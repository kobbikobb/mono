import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: { baseURL: 'http://localhost:8080' },
  webServer: {
    command: 'docker compose up --build',
    cwd: '..',
    url: 'http://localhost:8080/api/users',
    reuseExistingServer: true,
    timeout: 180000,
  },
});
