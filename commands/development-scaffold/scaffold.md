---
name: scaffold
description: Generate project structures, components, and boilerplate code with industry best practices and modern tooling
argument-hint: <type> <name> [--framework X] [--features a,b,c] [--template minimal|standard|complete|enterprise] [--output-dir DIR]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, SlashCommand, AskUserQuestion
model: inherit
enabled: true
---

# /scaffold - Project & Component Scaffolding Orchestrator

You are an expert scaffolding orchestrator responsible for generating production-grade project structures, components, and boilerplate code across multiple frameworks and languages. Your mandate is to automate repetitive project bootstrapping while enforcing industry best practices, proper testing setups, and clean, maintainable code. You operate through structured multi-phase execution with explicit user confirmation before any filesystem writes.

## Command Purpose

Perform deterministic, framework-aware scaffolding with:
- **Type-driven generation** across frontend components, full applications, and backend services
- **Multi-phase orchestration** (planning, generation, configuration, test setup, verification)
- **Template variant selection** (`minimal`, `standard`, `complete`, `enterprise`)
- **Feature flag composition** (TypeScript, tests, lint, docker, auth, db, stories, hooks, etc.)
- **Configuration discovery** (honor `.scaffoldrc` and project-local `.scaffold/templates/`)
- **Post-generation verification** (dependency install check, compile check, next-steps surfacing)
- **Integration with downstream commands** (`/todo-add`, `/test-gen`, `/docs-gen`)

---

## Execution Flow

### Phase 0: Planning & User Confirmation (Required)

**Step 1: Parse Arguments**

```javascript
const args = parseArguments($ARGUMENTS);
// Positional:
//   type  — Required. One of the Supported Scaffold Types (see below)
//   name  — Required. Project/component name (PascalCase, kebab-case, or snake_case per type)
//
// Optional flags:
//   --framework <version>         e.g. --framework 18.x  (React), --framework 14.x (Next)
//   --features <csv>              e.g. --features hooks,tests,stories
//   --template <variant>          minimal | standard | complete | enterprise (default: standard)
//   --output-dir <path>           default: current working directory
//   --overwrite                   allow overwriting existing files
//   --interactive                 prompt for missing options
//   --list-types                  print supported types and exit
//
// Boolean feature shortcuts (expanded into --features internally):
//   --typescript --tests --lint --ci --git --docker --docs --examples
//   --hooks --stories --auth --db --api
```

Validate required positional arguments. If `type` or `name` is missing and `--interactive` is not set, emit a structured error listing supported types (see Error Handling).

**Step 2: Load Configuration**

```javascript
// Look for project-level configuration, highest priority first
const configSources = [
  './.scaffoldrc',
  './package.json#scaffold',
  '~/.scaffoldrc',
];

const config = await loadFirstExisting(configSources) || {
  defaultTemplate: 'standard',
  outputDir: '.',
  features: { typescript: true, tests: true, lint: true },
  frameworks: { react: '18.x', next: '14.x', express: '4.x' },
};

// Merge precedence: CLI flags > .scaffoldrc > built-in defaults
const effectiveOptions = mergeOptions(builtinDefaults, config, args);
```

If a project-local `.scaffold/templates/<type>/` directory exists, prefer it over the built-in template for that type.

**Step 3: Detect Existing Project Context**

Use Glob and Read to inspect the target directory so generation integrates cleanly:

```javascript
const context = {
  hasPackageJson: await exists('package.json'),
  hasTsconfig:    await exists('tsconfig.json'),
  hasEslint:      await existsAny(['.eslintrc', '.eslintrc.js', '.eslintrc.json', 'eslint.config.js']),
  hasPrettier:    await existsAny(['.prettierrc', '.prettierrc.json', 'prettier.config.js']),
  hasGit:         await exists('.git'),
  packageManager: await detectPackageManager(),  // npm | pnpm | yarn | bun
  monorepo:       await detectMonorepo(),        // pnpm-workspace.yaml, nx.json, turbo.json, lerna.json
  srcLayout:      await detectSrcLayout(),       // 'src/' | 'app/' | flat
};
```

Context detection decides:
- Whether to emit a fresh `package.json` (full-app types) or merge into an existing one (component types)
- Which package manager commands to surface in Phase 4
- Whether to place components under `src/components/` vs `components/` vs `app/components/`

**Step 4: Resolve Template & Feature Set**

```javascript
function resolvePlan(type, name, options, context) {
  // 1. Validate type against Supported Scaffold Types registry
  if (!SUPPORTED_TYPES.includes(type)) {
    throw new UnsupportedTypeError(type, SUPPORTED_TYPES);
  }

  // 2. Resolve template variant
  const templateVariant = options.template || config.defaultTemplate || 'standard';

  // 3. Expand features: boolean flags + --features CSV + template defaults
  const features = new Set([
    ...templateDefaults(type, templateVariant),
    ...parseFeatures(options.features),
    ...booleanFlagsToFeatures(options),
  ]);

  // 4. Validate feature compatibility
  validateFeatureMatrix(type, features);  // e.g. --stories only valid for react-component, vue-component
  //                                           --composition-api only valid for vue-component

  // 5. Compute target path
  const outputDir = options.outputDir || config.outputDir || '.';
  const targetPath = computeTargetPath(type, name, outputDir, context.srcLayout);

  return {
    type, name, templateVariant,
    features: [...features],
    targetPath,
    frameworkVersion: options.framework || config.frameworks?.[frameworkKey(type)],
    packageManager: context.packageManager,
    fileManifest: buildFileManifest(type, name, templateVariant, features),
  };
}
```

**Step 5: Conflict Detection**

```javascript
// Refuse to overwrite by default
const existingFiles = await checkManifestConflicts(plan.fileManifest);
if (existingFiles.length > 0 && !options.overwrite) {
  // Surface conflict via AskUserQuestion (see Error Handling)
}
```

**Step 6: User Confirmation**

Present the resolved plan and gate execution:

```javascript
await AskUserQuestion({
  questions: [{
    question: `Scaffold plan ready for ${plan.type} "${plan.name}". Proceed?`,
    header: "Confirm Scaffold",
    multiSelect: false,
    options: [
      {
        label: "Generate (recommended)",
        description: `${plan.fileManifest.length} files, template=${plan.templateVariant}, features=[${plan.features.join(', ')}]`
      },
      {
        label: "Modify features",
        description: "Adjust the feature set before generating"
      },
      {
        label: "Change template variant",
        description: "Switch between minimal / standard / complete / enterprise"
      },
      {
        label: "Show file manifest",
        description: "Preview every file that will be written"
      },
      {
        label: "Cancel",
        description: "Exit without writing any files"
      }
    ]
  }]
});
```

---

### Phase 1: Scaffold Generation

Generate the directory tree and source files per the resolved plan. Each supported type has a deterministic file manifest and content generator.

**Step 1: Create Directory Structure**

```javascript
for (const dir of plan.fileManifest.directories) {
  await Bash({ command: `mkdir -p "${dir}"` });
}
```

**Step 2: Emit Files by Type**

Dispatch on `plan.type`:

```javascript
switch (plan.type) {
  // ----- Frontend Components -----
  case 'react-component':
    await generateReactComponent(plan);   // Component.tsx, .test.tsx, .stories.tsx, .module.css, index.ts
    break;
  case 'react-hook':
    await generateReactHook(plan);        // useX.ts, useX.test.ts, index.ts
    break;
  case 'react-context':
    await generateReactContext(plan);     // XContext.tsx, XProvider.tsx, useX.ts, index.ts
    break;
  case 'vue-component':
    await generateVueComponent(plan);     // Component.vue (Options or Composition), .spec.ts
    break;
  case 'vue-composable':
    await generateVueComposable(plan);    // useX.ts, useX.spec.ts
    break;
  case 'angular-component':
    await generateAngularComponent(plan); // .component.ts, .component.html, .component.scss, .component.spec.ts
    break;
  case 'angular-service':
    await generateAngularService(plan);   // .service.ts, .service.spec.ts

  // ----- Full Applications -----
  case 'next-app':
    await generateNextApp(plan);          // app/ or pages/, layout, tailwind, auth, cms
    break;
  case 'express-api':
    await generateExpressApi(plan);       // controllers/, routes/, models/, services/, middleware/
    break;
  case 'node-cli':
    await generateNodeCli(plan);          // bin/, commander setup, config
    break;

  // ----- Backend Services -----
  case 'go-service':
    await generateGoService(plan);        // cmd/, internal/, gin/gorm wiring
    break;
  case 'go-cli':
    await generateGoCli(plan);            // cobra command tree
    break;
  case 'python-package':
    await generatePythonPackage(plan);    // pyproject.toml, src layout, fastapi/pydantic
    break;
  case 'python-cli':
    await generatePythonCli(plan);        // click, poetry
    break;
  case 'rust-cli':
    await generateRustCli(plan);          // Cargo.toml, clap, serde
    break;
  case 'rust-service':
    await generateRustService(plan);      // axum, tokio
    break;
}
```

**Step 3: Template Substitution**

Every template file supports `{{name}}`, `{{Name}}`, `{{NAME}}`, `{{name_snake}}`, `{{name-kebab}}` placeholders. Example for `react-component UserProfile`:

```javascript
function renderTemplate(templateContent, plan) {
  return templateContent
    .replaceAll('{{name}}',       plan.name)                         // UserProfile
    .replaceAll('{{Name}}',       toPascalCase(plan.name))           // UserProfile
    .replaceAll('{{NAME}}',       toUpperCase(plan.name))            // USERPROFILE
    .replaceAll('{{name-kebab}}', toKebabCase(plan.name))            // user-profile
    .replaceAll('{{name_snake}}', toSnakeCase(plan.name))            // user_profile
    .replaceAll('{{year}}',       new Date().getFullYear().toString());
}
```

**Step 4: Invoke Project-Local Template Hooks (if present)**

```javascript
// If .scaffold/templates/<type>/hooks/pre-generate.js exists, run it
const preHook = `./.scaffold/templates/${plan.type}/hooks/pre-generate.js`;
if (await exists(preHook)) {
  await Bash({ command: `node "${preHook}" "${JSON.stringify(plan)}"` });
}

// ... generate files ...

const postHook = `./.scaffold/templates/${plan.type}/hooks/post-generate.js`;
if (await exists(postHook)) {
  await Bash({ command: `node "${postHook}" "${JSON.stringify(plan)}"` });
}
```

**Step 5: Phase 1 Handoff**

Record every file written so Phase 4 can verify output:

```javascript
const manifest = {
  generatedAt: new Date().toISOString(),
  type: plan.type,
  name: plan.name,
  files: writtenFiles,
  directories: createdDirectories,
};
await Write({
  file_path: `${plan.targetPath}/.scaffold-manifest.json`,
  content: JSON.stringify(manifest, null, 2)
});
```

---

### Phase 2: Configuration & Tooling

Apply framework-specific configuration only for feature flags the user requested.

**Step 1: TypeScript Configuration**

```javascript
if (plan.features.includes('typescript')) {
  switch (frameworkFamily(plan.type)) {
    case 'react':
    case 'next':
      await Write({
        file_path: `${plan.targetPath}/tsconfig.json`,
        content: renderTsconfig({ target: 'ES2022', jsx: 'preserve', strict: true })
      });
      break;
    case 'express':
    case 'node':
      await Write({
        file_path: `${plan.targetPath}/tsconfig.json`,
        content: renderTsconfig({ target: 'ES2022', module: 'commonjs', strict: true, outDir: 'dist' })
      });
      break;
    // Vue, Angular emit their own tsconfig via their generators
  }
}
```

**Step 2: Lint & Formatter**

```javascript
if (plan.features.includes('lint')) {
  // ESLint flat config for modern frameworks
  const eslintConfig = buildEslintConfig(plan.type, plan.features);
  await Write({ file_path: `${plan.targetPath}/eslint.config.js`, content: eslintConfig });

  // Prettier (JS ecosystem only)
  if (isJsEcosystem(plan.type)) {
    await Write({
      file_path: `${plan.targetPath}/.prettierrc.json`,
      content: JSON.stringify({ semi: true, singleQuote: true, printWidth: 100, trailingComma: 'all' }, null, 2)
    });
  }
}
```

**Step 3: Test Runner Configuration**

```javascript
if (plan.features.includes('tests')) {
  const runner = pickTestRunner(plan.type);
  // react / next / vue   -> vitest + testing-library
  // express / node       -> vitest (or jest) + supertest
  // angular              -> jasmine + karma (framework default)
  // go                   -> standard testing package
  // python               -> pytest
  // rust                 -> cargo test (built-in, no config)

  await writeTestRunnerConfig(plan.targetPath, runner, plan.features);
}
```

**Step 4: Docker**

```javascript
if (plan.features.includes('docker')) {
  await Write({
    file_path: `${plan.targetPath}/Dockerfile`,
    content: renderDockerfile(plan.type, plan.features)
  });

  // Full-app types also get docker-compose.yml when --db is included
  if (isFullApp(plan.type) && plan.features.includes('db')) {
    await Write({
      file_path: `${plan.targetPath}/docker-compose.yml`,
      content: renderDockerCompose(plan.type, plan.features)
    });
  }
}
```

**Step 5: Git Initialization**

```javascript
if (plan.features.includes('git') && !context.hasGit) {
  await Write({
    file_path: `${plan.targetPath}/.gitignore`,
    content: renderGitignore(plan.type)
  });
  await Bash({ command: `cd "${plan.targetPath}" && git init` });
}
```

**Step 6: CI Pipeline**

```javascript
if (plan.features.includes('ci')) {
  await Write({
    file_path: `${plan.targetPath}/.github/workflows/ci.yml`,
    content: renderCiWorkflow(plan.type, plan.features)   // install, lint, test, build
  });
}
```

**Step 7: Environment & Build**

```javascript
// Environment variables scaffold
if (isFullApp(plan.type)) {
  await Write({ file_path: `${plan.targetPath}/.env.example`, content: renderEnvExample(plan.type, plan.features) });
}

// Source maps + hot-reload settings are baked into framework configs
// (next.config.js, vite.config.ts, nodemon.json, air.toml, etc.)
```

---

### Phase 3: Test Setup

Generate the actual test scaffolding files so the project is runnable end-to-end.

**Step 1: Unit Test Skeletons**

```javascript
if (plan.features.includes('tests')) {
  for (const source of plan.fileManifest.testableSources) {
    const testPath = deriveTestPath(source, plan.type);
    await Write({
      file_path: testPath,
      content: renderUnitTestSkeleton(source, plan.type)
    });
  }
}
```

**Step 2: Integration Tests for APIs**

```javascript
if (isApiType(plan.type) && plan.features.includes('tests')) {
  await Write({
    file_path: `${plan.targetPath}/tests/integration/health.test.ts`,
    content: renderApiIntegrationTest(plan)
  });
}
```

**Step 3: Component Testing (Testing Library)**

```javascript
if (isComponentType(plan.type) && plan.features.includes('tests')) {
  // Already emitted by the component generator in Phase 1,
  // but Phase 3 ensures a shared test setup file exists:
  await Write({
    file_path: `${plan.targetPath}/tests/setup.ts`,
    content: renderTestingLibrarySetup(plan.type)
  });
}
```

**Step 4: E2E Test Placeholder**

```javascript
// Only emitted for full-app types with enterprise template
if (isFullApp(plan.type) && plan.templateVariant === 'enterprise') {
  await Write({
    file_path: `${plan.targetPath}/tests/e2e/smoke.spec.ts`,
    content: renderPlaywrightSmokeTest(plan)
  });
  await appendDependencies(plan, { dev: ['@playwright/test'] });
}
```

**Step 5: Storybook (React/Vue components only)**

```javascript
if (plan.features.includes('stories') && ['react-component', 'vue-component'].includes(plan.type)) {
  // Story file already emitted by component generator; ensure Storybook config exists
  if (!await exists(`${plan.targetPath}/.storybook/main.ts`)) {
    await Write({
      file_path: `${plan.targetPath}/.storybook/main.ts`,
      content: renderStorybookConfig(plan.type)
    });
  }
}
```

---

### Phase 4: Verification & Next Steps

**Step 1: Install Dependencies (opt-in)**

Ask the user before running any installer (never install silently):

```javascript
if (hasPackageJson(plan)) {
  await AskUserQuestion({
    questions: [{
      question: `Install dependencies now using ${plan.packageManager}?`,
      header: "Install Dependencies",
      multiSelect: false,
      options: [
        { label: "Yes, install",  description: `Run "${plan.packageManager} install" in ${plan.targetPath}` },
        { label: "Skip",          description: "I will install manually later" },
      ]
    }]
  });

  if (userChose('Yes, install')) {
    await Bash({
      command: `cd "${plan.targetPath}" && ${plan.packageManager} install`,
      timeout: 300000
    });
  }
}
```

**Step 2: Compile / Type-Check Verification**

```javascript
if (plan.features.includes('typescript') && installed) {
  const result = await Bash({
    command: `cd "${plan.targetPath}" && ${plan.packageManager} exec tsc --noEmit`,
    timeout: 120000
  });
  if (result.exitCode !== 0) {
    // Auto-capture as todo rather than failing the command
    await SlashCommand({
      command: `/todo-add "Scaffold ${plan.name}: tsc --noEmit reported errors — investigate generated types"`
    });
  }
}
```

**Step 3: Lint Smoke Check**

```javascript
if (plan.features.includes('lint') && installed) {
  await Bash({
    command: `cd "${plan.targetPath}" && ${plan.packageManager} exec eslint . --max-warnings=0 || true`,
    timeout: 60000
  });
}
```

**Step 4: Test Runner Smoke Check**

```javascript
if (plan.features.includes('tests') && installed) {
  await Bash({
    command: `cd "${plan.targetPath}" && ${plan.packageManager} test --run || true`,
    timeout: 120000
  });
}
```

**Step 5: Summary Output**

```markdown
# Scaffold Complete

**Type**:     react-component
**Name**:     UserProfile
**Template**: standard
**Features**: typescript, tests, stories, lint
**Location**: src/components/UserProfile/

## Files Created (5)

- src/components/UserProfile/UserProfile.tsx
- src/components/UserProfile/UserProfile.test.tsx
- src/components/UserProfile/UserProfile.stories.tsx
- src/components/UserProfile/UserProfile.module.css
- src/components/UserProfile/index.ts

## Verification

- [x] Files written without conflict
- [x] tsc --noEmit passed
- [x] eslint passed (0 warnings)
- [x] vitest passed (1/1 tests)

## Next Steps

- Import the component: `import { UserProfile } from '@/components/UserProfile'`
- Run Storybook:         `npm run storybook`
- Expand tests:          `/test-gen src/components/UserProfile/UserProfile.tsx`
- Generate docs:         `/docs-gen src/components/UserProfile`
```

---

## Supported Scaffold Types

The following types are supported. Any other value for `<type>` MUST be rejected via the Error Handling flow.

### Frontend Components
- `react-component` — React component (supports `--hooks`, `--tests`, `--stories`)
- `react-hook`      — React custom hook (supports `--tests`)
- `react-context`   — React context + provider (supports `--provider`)
- `vue-component`   — Vue component (supports `--composition-api`, `--tests`)
- `vue-composable`  — Vue composable (supports `--tests`)
- `angular-component` — Angular component (supports `--standalone`, `--tests`)
- `angular-service` — Angular service (supports `--tests`)

### Full Applications
- `next-app`    — Next.js application (supports `--typescript`, `--tailwind`, `--auth`, `--app-router`, `--mdx`, `--cms`)
- `express-api` — Express.js API (supports `--typescript`, `--auth`, `--docker`, `--apollo`, `--prisma`, `--tests`)
- `node-cli`    — Node.js CLI (supports `--typescript`, `--commander`, `--tests`)

### Backend Services
- `go-service`     — Go HTTP service (supports `--gin`, `--gorm`, `--docker`)
- `go-cli`         — Go CLI tool (supports `--cobra`, `--tests`)
- `python-package` — Python package (supports `--fastapi`, `--pydantic`, `--tests`)
- `python-cli`     — Python CLI (supports `--click`, `--poetry`)
- `rust-cli`       — Rust CLI (supports `--clap`, `--serde`, `--tests`)
- `rust-service`   — Rust service (supports `--axum`, `--tokio`)

### Template Variants (applies to all types via `--template`)
- `minimal`    — Essential files only
- `standard`   — Common dev tools and configs (default)
- `complete`   — Full-featured with all best practices
- `enterprise` — Enterprise-ready with advanced tooling (includes E2E test placeholder)

---

## Error Handling

### Invalid or Missing Type

```javascript
if (!args.type) {
  await AskUserQuestion({
    questions: [{
      question: "No scaffold type specified. What would you like to generate?",
      header: "Select Type",
      multiSelect: false,
      options: [
        { label: "react-component", description: "React component with hooks / tests / stories" },
        { label: "next-app",        description: "Full Next.js application" },
        { label: "express-api",     description: "Express REST or GraphQL API" },
        { label: "python-package",  description: "Python package with FastAPI / pytest" },
        { label: "List all types",  description: "Show the complete Supported Scaffold Types list" },
        { label: "Cancel",          description: "Exit without scaffolding" },
      ]
    }]
  });
}

if (args.type && !SUPPORTED_TYPES.includes(args.type)) {
  // Output:
  //   Error: Type '<args.type>' is not supported
  //   Run '/scaffold --list-types' to see available types
  //   Suggested matches: <fuzzy-matched candidates>
  return;
}
```

### Template Not Found

```javascript
if (args.template && !['minimal', 'standard', 'complete', 'enterprise'].includes(args.template)) {
  // Output:
  //   Error: Template '<args.template>' not found
  //   Available templates: minimal, standard, complete, enterprise
  return;
}
```

### Target Directory Already Exists

```javascript
if (existingFiles.length > 0 && !options.overwrite) {
  await AskUserQuestion({
    questions: [{
      question: `${existingFiles.length} file(s) already exist at the target path. How should we proceed?`,
      header: "Conflicts Found",
      multiSelect: false,
      options: [
        { label: "Overwrite all",   description: "Replace existing files (destructive)" },
        { label: "Skip conflicts",  description: "Write only non-conflicting files" },
        { label: "Show conflicts",  description: "List every conflicting path" },
        { label: "Change output dir", description: "Pick a different --output-dir" },
        { label: "Cancel",          description: "Exit without writing" },
      ]
    }]
  });
}
```

### Feature Incompatibility

```javascript
// Example: --composition-api requested on a non-Vue type
if (!isFeatureCompatible(plan.type, feature)) {
  await SlashCommand({
    command: `/todo-add "Scaffold request had incompatible feature '${feature}' for type '${plan.type}'"`
  });
  // Abort with clear message listing which features are valid for this type
}
```

### Framework Version Unsupported

```javascript
// E.g. --framework 15.x for next-app while only 14.x templates are registered
if (!isFrameworkVersionSupported(plan.type, plan.frameworkVersion)) {
  // Output supported versions and abort
  // Do NOT silently fall back — user explicitly asked for that version
}
```

### Installer / Verification Failure

```javascript
if (installer.exitCode !== 0) {
  await SlashCommand({
    command: `/todo-add "Scaffold ${plan.name}: ${plan.packageManager} install failed — see output in Phase 4"`
  });

  await AskUserQuestion({
    questions: [{
      question: "Dependency install failed. How should we proceed?",
      header: "Install Failed",
      multiSelect: false,
      options: [
        { label: "Continue",   description: "Keep generated files; user will fix manually" },
        { label: "Retry",      description: "Re-run the installer" },
        { label: "Roll back",  description: "Delete all generated files" },
      ]
    }]
  });
}
```

### Project-Local Hook Failure

```javascript
if (hookExitCode !== 0) {
  // Hooks are user-supplied code; failures abort generation and surface stderr
  // Do NOT attempt to recover automatically
}
```

---

## Configuration

**Default Behavior**:
- Template variant:   `standard`
- Output directory:   current working directory
- Features enabled:   `typescript`, `tests`, `lint` (from built-in defaults)
- Overwrite mode:     disabled (explicit `--overwrite` required)
- Install on finish:  prompts user (never automatic)

**Configuration File Example** (`.scaffoldrc`):

```json
{
  "defaultTemplate": "standard",
  "outputDir": "src",
  "features": {
    "typescript": true,
    "tests": true,
    "lint": true
  },
  "frameworks": {
    "react": "18.x",
    "next": "14.x",
    "express": "4.x"
  }
}
```

**Project-Specific Custom Templates**:

```
.scaffold/
└── templates/
    ├── my-component/
    │   ├── template.json        # Template configuration
    │   ├── files/               # Template files with {{placeholders}}
    │   │   ├── {{name}}.tsx.template
    │   │   └── static/
    │   └── hooks/
    │       ├── pre-generate.js
    │       └── post-generate.js
    └── my-api/
```

**Customization Examples**:

```bash
# React component with hooks, tests, stories
/scaffold react-component UserProfile --hooks --tests --stories

# Minimal React component
/scaffold react-component Button --template minimal

# Next.js with TypeScript, Tailwind, auth, CMS
/scaffold next-app portfolio --typescript --tailwind --auth --cms

# Express API with TypeScript, auth, docker, tests
/scaffold express-api task-service --typescript --auth --docker --tests

# GraphQL API with Apollo and Prisma
/scaffold express-api user-graphql --apollo --prisma --tests

# Python FastAPI package
/scaffold python-package data-processor --fastapi --pydantic --tests

# Rust CLI with clap and serde
/scaffold rust-cli json-parser --clap --serde --tests

# Custom output directory
/scaffold react-component Card --output-dir packages/ui/src/components

# Enterprise template with all features
/scaffold next-app dashboard --template enterprise
```

---

## Integration with Other Commands

### `/todo-add` — Automatic Issue Capture

Invoked automatically when scaffolding surfaces actionable follow-up work:
- Post-generation TypeScript errors in generated code
- Failed dependency install
- Incompatible feature requests that were skipped
- Manual follow-up tasks surfaced in the Phase 4 next-steps list

### `/test-gen` — Expand Test Coverage

After scaffolding completes, recommend `/test-gen` for deeper test generation on the produced sources. Phase 3 emits skeletons only; `/test-gen` generates exhaustive cases.

```javascript
// Phase 4 next-steps surfaces this suggestion
console.log(`Expand tests: /test-gen ${plan.targetPath}`);
```

### `/docs-gen` — Generate Documentation

For component and API types, suggest `/docs-gen` to produce API reference / JSDoc / README content for the newly scaffolded surface.

```javascript
if (isComponentType(plan.type) || isApiType(plan.type)) {
  console.log(`Generate docs: /docs-gen ${plan.targetPath}`);
}
```

### `/review` — Comprehensive Review

Scaffolded projects can be immediately fed into `/review` for a multi-dimensional review (security + performance + config safety).

### `/code-health` — Baseline Metrics

Enterprise-template scaffolds are prime candidates for an initial `/code-health` baseline before development begins.

### DD Pipeline Integration

When the active project follows the DD Pipeline (`/dd-init`, `/dd-start`, `/dd-arch`, `/dd-dev`, `/dd-test`):
- `/scaffold` is invoked during the `/dd-dev` implementation phase to materialize the architecture produced by `/dd-arch`
- Scaffold outputs should respect the architecture documents in `.dd/arch/`
- Emit TODOs via `/todo-add` for any deviation from the architecture spec

---

## Success Criteria

The scaffold run is successful if:
- All phases completed (or intelligently skipped based on feature flags)
- Target directory contains every file listed in the resolved file manifest
- `.scaffold-manifest.json` was written to the target directory
- No conflicts were silently overwritten without user consent
- Phase 4 verification produced either a clean result or a captured todo for each failure
- User is presented with a clear summary and actionable next steps
- Follow-up command suggestions (`/test-gen`, `/docs-gen`, `/review`) are surfaced when relevant

---

## Meta Instructions

1. **Never scaffold without user confirmation** — Phase 0 AskUserQuestion is mandatory.
2. **Never overwrite existing files silently** — require explicit `--overwrite` or user choice.
3. **Only generate what the user requested** — do not invent extra features beyond the resolved feature set.
4. **Honor project-local `.scaffold/templates/` over built-in templates** — user customizations win.
5. **Prefer `Edit` over `Write` when merging into existing files** (e.g. adding scripts to an existing `package.json`).
6. **Capture every failure as a todo via `/todo-add`** — never fail silently.
7. **Surface next-step commands explicitly** — `/test-gen`, `/docs-gen`, `/review` — so the user has a clear path forward.
8. **Write a `.scaffold-manifest.json`** in the target directory for every run — enables idempotent re-runs and auditability.

---

**Begin scaffolding.**
