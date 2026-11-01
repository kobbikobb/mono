import { test, expect } from '@playwright/test';

test('should render at least one user', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('listitem').first()).not.toBeEmpty();
});

test('should show an added name in the list', async ({ page }) => {
  await page.goto('/');
  const name = `anna-${Date.now()}`;
  await page.getByPlaceholder('Name').fill(name);
  await page.getByRole('button', { name: 'Add' }).click();
  await expect(page.getByRole('listitem').filter({ hasText: name })).toBeVisible();
});
