import { test as it, expect } from '@playwright/test';

it('should render at least one user', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('listitem').first()).not.toBeEmpty();
});

it('should show an added name in the list', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Name').fill('anna');
  await page.getByRole('button', { name: 'Add' }).click();
  await expect(page.getByRole('listitem').filter({ hasText: 'anna' })).toBeVisible();
});
