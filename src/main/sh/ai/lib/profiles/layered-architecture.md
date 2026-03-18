- Controller should call services
- Services should not know anything about the user layer, unless it is specifically a helper service for a user. For
  example, use http codes internally that binds it directly to a specific user layer type - REST or HTTP controllers
- Service user can be Web controller, CLI layer, Swing or EclipseRPC or JavaFX layer, test or another service
