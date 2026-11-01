import { test, expect } from '@playwright/test';

test('renders at least one user', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('listitem').first()).not.toBeEmpty();
});

test('added name shows up in the list', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Name').fill('anna');
  await page.getByRole('button', { name: 'Add' }).click();
  await expect(page.getByRole('listitem').filter({ hasText: 'anna' })).toBeVisible();
});
