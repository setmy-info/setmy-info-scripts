- Use application.yaml for properties and Spring profiles: application-local.yaml, application-ci.yaml,
  application-dev.yaml, application-test.yaml, application-live.yaml
- Sensitive values should be overridable via environment variables (e.g., ${ABC_SERVER_PASSWORD:123456})
