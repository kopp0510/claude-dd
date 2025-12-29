# 測試模式範例

## 單元測試 (JavaScript/Jest)

```javascript
describe('calculateTotal', () => {
  it('should calculate total with tax correctly', () => {
    expect(calculateTotal(100, 0.08)).toBe(108);
  });

  it('should handle zero tax rate', () => {
    expect(calculateTotal(100, 0)).toBe(100);
  });

  it('should throw error for negative amounts', () => {
    expect(() => calculateTotal(-10, 0.08)).toThrow();
  });
});
```

## 單元測試 (Python/pytest)

```python
def test_calculate_total_with_tax():
    assert calculate_total(100, 0.08) == 108

def test_calculate_total_zero_tax():
    assert calculate_total(100, 0) == 100

def test_calculate_total_negative_amount():
    with pytest.raises(ValueError):
        calculate_total(-10, 0.08)
```

## React 元件測試

```javascript
import { render, screen, fireEvent } from '@testing-library/react';

test('UserProfile displays user information correctly', () => {
  const user = { name: 'John Doe', email: 'john@example.com' };
  render(<UserProfile user={user} />);

  expect(screen.getByText('John Doe')).toBeInTheDocument();
  expect(screen.getByText('john@example.com')).toBeInTheDocument();
});

test('UserProfile calls onEdit when edit button clicked', () => {
  const mockOnEdit = jest.fn();
  render(<UserProfile user={user} onEdit={mockOnEdit} />);

  fireEvent.click(screen.getByRole('button', { name: /edit/i }));
  expect(mockOnEdit).toHaveBeenCalledWith(user.id);
});
```

## API 整合測試

```javascript
describe('POST /api/users', () => {
  it('should create a new user with valid data', async () => {
    const userData = {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'securePassword123'
    };

    const response = await request(app)
      .post('/api/users')
      .send(userData)
      .expect(201);

    expect(response.body).toMatchObject({
      name: userData.name,
      email: userData.email
    });
    expect(response.body.password).toBeUndefined();
  });
});
```

## E2E 測試 (Playwright)

```javascript
test('user can complete purchase workflow', async ({ page }) => {
  await page.goto('/products');

  // 加入購物車
  await page.click('[data-testid="add-to-cart-123"]');
  await expect(page.locator('[data-testid="cart-count"]')).toHaveText('1');

  // 結帳
  await page.click('[data-testid="cart-button"]');
  await page.click('[data-testid="checkout-button"]');

  // 填寫表單
  await page.fill('[data-testid="email"]', 'test@example.com');
  await page.fill('[data-testid="card-number"]', '4242424242424242');

  // 完成購買
  await page.click('[data-testid="place-order"]');
  await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
});
```

## Test Fixtures

```javascript
// User factory for test data
const createUser = (overrides = {}) => ({
  id: '123',
  name: 'Test User',
  email: 'test@example.com',
  createdAt: new Date(),
  ...overrides
});

// Database seeding
beforeEach(async () => {
  await db.seed.run();
});

afterEach(async () => {
  await db.cleanup();
});
```
