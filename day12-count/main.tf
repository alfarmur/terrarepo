provider "aws" {
  
}
variable "ser" {
    type = list(string)

    default = [ "bastion","frontend","backend" ]
}

resource "aws_instance" "name" {
  ami="ami-0cae6d6fe6048ca2c"
  instance_type = "t2.micro"
  count = length(var.ser)
  tags = { 
    #Name = "dev-${count.index}"
    Name = var.ser[count.index]
  }
}
