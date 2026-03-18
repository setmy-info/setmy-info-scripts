- Components should be implemented in a bottom-up direction. Bottom-up means that higher-level components depend on and
  know lower-level components, but lower-level components or modules do not know anything about upper-layer components
  or modules. Each component or module can provide class models, DTOs, value objects, services, or API functionality to
  operate on populated data. Typically, upper layers are user-oriented, while lower layers are oriented toward data
  storage, in-house systems, or external APIs. APIs act similarly to data storages or databases—these provide data upon
  request. Data models (VOs, DTOs) are designed according to specifications and validated through unit tests to ensure
  they support data transport or storage using a ubiquitous language and semantically correct structures. Tests also
  verify that any data transformations are correct. For example, consider a use case where an acquirer or bank accepts
  end-of-day transaction files over an SSH connection in a specific text format with strictly defined file naming
  conventions. The developer should first create components that provide SSH communication with proper credentials and
  verify that the connection works. Then, implement a class model representing the file name and verify that it
  correctly produces semantically valid file names. Next, implement the class model hierarchy responsible for generating
  the file content according to the specification and prove its correctness through tests. Finally, integrate all
  components so that the main software can semantically populate the class models, generate the correctly formatted
  files, and send them over SSH. The order should, therefore, be: SSH components first, then file generation, and finally
  integration into the main software.
