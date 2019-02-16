//Exercise: Swift Variables
//1
let const1 = 25
//2
var exVar:Int = 15
//3
var imVar = 10
//4
print(exVar+imVar)
//5
var num1 = 12
var num2 = 5.5
//6
var prod = Double(num1) * num2
//7
var str1 = "iOS"
str1+="Development"
//8
var emoji1 = "iPhone😄"
//9
var emoji2 = "iPhone\u{301}"
//10
var eq = emoji1==emoji2

// Exercise: Swift Arrays
//1
var arr1:[Int] = []
//2
var arr2:[String] = []
arr2 = ["val1","val2","val3"]
//3
arr2+=["String 4", "String 5"]
//4
arr2.insert("Random", at: 2)
//5
var arr3: [Any] = [12 , "PewDiePie" , true , 176.224 , "J"]
//6
arr3.remove(at: 0)

// Exercise: Swift Loops
//1
var empArr:[Int] = []
//2
for i in 1...100 {
    var tot = 0
    for x in 1...i {
        if i%x == 0 {
            tot+=1
        }
    }
    if tot<=2 {
        empArr.append(i)
    }
}

//3
for i in empArr {
    var sumofDigit = 0;
    
    if i>=10 {
        sumofDigit = i/10+i%10
    }
    else {
        sumofDigit = i%10
    }
    
    print("prime number:\(i) sum of digits:\(sumofDigit)")
}

//4
var i=0
repeat {
    empArr[i]+=5
    i+=1
} while(i<empArr.count)

//5
var str : String = "Hello"
var charArr = Array(str)
for i in 0..<charArr.count {
    print("\(charArr[i]) index:\(i)")
}

// Exercise: Swift Functions
//1
func add(num1: Double, num2: Double) -> Double {
    return num1+num2
}

//2
func substract(num1: Int, num2: Int )-> Int {
    return num1-num2
}

//3
func multiply(num1: Float, num2: Float)-> Float {
    return num1*num2
}

//4
print("sum of 2 and 3 is \(add(num1: 2,num2: 3))")
print("difference of 2 and 3 is \(substract(num1: 2,num2: 3))")
print("product of 2 and 3 is \(multiply(num1: 2,num2: 3))")

// Exercise: Conditions
//1
func score2grade (_ score: Int) -> String {
    if score>=80 {
        return "A"
    }
    else if score>=60 && score<80 {
        return "B"
    }
    else if score>=50 && score<60 {
        return "C"
    }
    else if score>=45 && score<50 {
        return "D"
    }
    else if score>=25 && score<45 {
        return "E"
    }
    else {
        return "F"
    }
}
//2
func recOrSqu (_ length: Float, _ breadth: Float) -> String {
    if length == breadth {
        return "Square"
    }
    else {
        return "Rectangle"
    }
}

// Exercise: Swift Dictionary and Tuples
//1
var dic: [Int: String] = [:]
//2
dic = [1:"Amy", 2:"Bob", 3:"Cathy", 4:"David", 5:"Edward"]
//3
for (userid, name) in dic {
    print("The name of id: \(userid) is '\(name)'.")
}
//4
for key in dic.keys {
    print("Key: \(key)")
}
//5
typealias iamstring = String
var MyTuple: (iamstring, iamstring) = ("","")
//6
MyTuple = ("a","b")
//7
print("Both values of the tuple:")
print(MyTuple.0)
print(MyTuple.1)


// Exercise: Swift Optionals
//1
let optvar : Int? = nil
//2
let unwrapme : String? = nil
if let unwrappedValue : String = unwrapme{
    print("The value of unwrapme is: "+unwrappedValue)
}
else {
    print("unwrapme is nil")
}

//3
var optionalString: String? = "Hello, World!"
var optionalInt: Int? = 123
var optionalDoublr: Double? = 123.456
var optionalBoolean: Bool? = true
var optionalTuple: (Int, String)? = (1,"a")
var optionalArray: [Float]? = [1.2, 3.6]

//4
var value1 : Int?
var defaultValue : Int = 7

if value1 != nil {
    print("value1 is: \(value1)")
}
else {
    value1 = defaultValue
    print("value1 is: \(value1)")
}

//4
//var value1 : Int?
//var defaultValue : Int = 7

var value2 = value1 ?? defaultValue
print("value2 is: \(value2)")

//5
guard txtname.text == nil else {
    print("No name provided")
}

guard txtaddress.text == nil else {
    print("No address provided")
}

sendToServer(name , address)
