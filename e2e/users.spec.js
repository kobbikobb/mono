import { test, expect } from '@playwright/test';

test('renders at least one user', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('listitem').first()).not.toBeEmpty();
});
