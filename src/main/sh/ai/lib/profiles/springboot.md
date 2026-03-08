- Spring boot 4.x
- application.yaml for properties and by spring profiles application-local.yaml, application-ci.yaml,
  application-dev.yaml, application-test.yaml, application-live.yaml
- Sensitive values should be overridable via environment variables (e.g., ${ABC_SERVER_PASSWORD:123456})
