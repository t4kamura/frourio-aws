provider "aws" {
  region  = "ap-northeast-1"
  profile = "default"
}

variable basename {
  default = "frourio-app"
}
