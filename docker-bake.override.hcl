target "default" {
  inherits = ["shared"]
  args = {
    BUILD_TITLE = "Apt mirror & cacher"
    BUILD_DESCRIPTION = "A dubo image for apt mirror & cacher"
  }
  tags = [
    "dubodubonduponey/aptutil",
  ]
}
