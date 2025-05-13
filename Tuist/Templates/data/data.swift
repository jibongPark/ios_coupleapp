import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "Feature module template",
    attributes: [
        nameAttribute
    ],
    items: [
        // MARK: Project
        .file(path: "\(nameAttribute)Data/Project.swift",
              templatePath: "../stencil/dataProject.stencil"),
        
        // MARK: Sources
        .file(path: "\(nameAttribute)Data/Sources/sample.swift",
              templatePath: "../stencil/sample.stencil"),
        
        // MARK: Tests
        .file(path: "\(nameAttribute)Data/Tests/Sources/sample.swift",
              templatePath: "../stencil/sample.stencil"),
    ]
)

