- Mermaid class diagram should contain example class model elements to be filled:
  Person --> BiologicalGender: uses
  Person o-- Book
  Person *-- "1..1" Address
  Person *-- "1..1" Passport
  Employee --|> Person
  Student --|> Person
  Employee ..|> WorkerInterface
- Layered systems class model should contain:
  ExampleController o-- ExampleService
  ExampleService o-- ExampleRepository
  ExampleService o-- ExampleValidation
  ExampleService o-- ExampleMapper
  ExampleController --> ExampleRequestDTO: uses
  ExampleController --> ExampleResponseDTO: uses
  ExampleService --> ExampleRequest: uses
  ExampleService --> ExampleResponse: uses
  ExampleValidation --> ExampleRequest: uses
  ExampleRepository --> Example: uses
  ExampleService --> Example: uses
