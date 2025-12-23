variable "stringInput" {
  type    = string
  default = "hello world"
}

variable "arrayInput" {
  type    = list(string)
  default = ["a", "b", "c"]
}
