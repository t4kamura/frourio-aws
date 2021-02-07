provider "aws" {
  version = "~> 2.0"
  region  = "ap-northeast-1"
  profile = "default"
}

variable basename {
  default = "frourio-app"
}
