param stringInput string = 'hello world'
param arrayInput array = [
  'a'
  'b'
  'c'
]

output containsString bool = contains(stringInput, 'hello')
output containsArray bool = contains(arrayInput, 'a')

output takeString string = take(stringInput, 5)
output takeArray array = take(arrayInput, 2)

output indexOfString int = indexOf(stringInput, 'o')
output indexOfArray int = indexOf(arrayInput, 'b')

output lengthString int = length(stringInput)
output lengthArray int = length(arrayInput)
