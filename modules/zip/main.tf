data "archive_file" "emailConfirmation-lambda" {
  type        = "zip"
  source_dir = "${path.root}/src/lambdas/${var.file}"
  output_path = "${path.root}/dist-aws/${var.folder}.zip"
}