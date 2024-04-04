# README

A Ruby on Rails application that provides APIs to store and  
retrieve objects/files using an id, name or a path.

Requirement

Amazon S3 Credentials needs to be added in the **.env**

Authentication Identifier needs to be set in the .env

DB Credential can be update in `config/database.yml`

Migration needs to run

run `rails server` to start app


# Note

The Storage service support the following methods:
- AWS S3, the original.
- Minio, open-source and built in Golang.
- Digital Ocean Spaces.
- Linode Object Storage.

Tested with S3 and Digital Ocean Spaces.