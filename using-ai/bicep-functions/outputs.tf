output "containsString" {
  value = strcontains(var.stringInput, "hello")
}

output "containsArray" {
  value = contains(var.arrayInput, "a")
}

output "takeString" {
  value = substr(var.stringInput, 0, 5)
}

output "takeArray" {
  value = slice(var.arrayInput, 0, 2)
}

# Terraform does not have a built-in function for string index.
# output "indexOfString" {
#   value = ...
# }

output "indexOfArray" {
  value = index(var.arrayInput, "b")
}

output "lengthString" {
  value = length(var.stringInput)
}

output "lengthArray" {
  value = length(var.arrayInput)
}
