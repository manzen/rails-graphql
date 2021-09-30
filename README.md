# rails-graphql

## 環境構築

```
$ docker-compose build
$ docker-compose up
$ docker-compose exec app rails db:create
```

## gem install

add gems

```
gem 'graphql'
gem 'graphiql-rails'
```

```
$ $ docker-compose exec app bundle i
```

## generate graphql

```
$ docker-compose exec app rails generate graphql:install
```

## Create Object

```
$ docker-compose exec app rails g model User name:string email:string
$ docker-compose exec app rails db:migrate
$ docker-compose exec app rails c
$ User.create(name: "Taro Yamada", email: "yamada-taro@test.com")
$ User.create(name: "Jiro Yamada", email: "yamada-jiro@test.com")
```

## Create Type

後で参照する時のfieldを定義する

```
$ docker-compose exec app rails g graphql:object User
```

すでにDBに定義が存在すれば自動でfieldを生成

graphql/type/user_type.rb

```ruby:user_type.rb
module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :email, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
```

## Create Query

CRUDのRの部分

graphql/type/query_type.rb

```ruby:query_type.rb
module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end
    
    # 追記
    field :users, [Types::UserType], null: false
    def users
      User.all
    end
    
    # 追記
    field :user, Types::UserType, null: false do
      argument :id, Int, required: false
    end
    def user(id:)
      User.find(id)
    end
  end
end
```

## Query Test

Routeに以下を追記し、再起動
```
if Rails.env.development?
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
end
```

app/assets/config/manifest.jsに以下を追記
```
//= link graphiql/rails/application.css
//= link graphiql/rails/application.js
```

[http://localhost:3000/graphiql](http://localhost:3000/graphiql)へアクセスし、以下のクエリを投げる

```
{
  users {
    id
    name
    email
  }
}
```

```
{
  user(id:1) {
    id
    name
    email
  }
}
```

## CreateMutation

CRUDのCUD部分

Create

```
$ docker-compose exec app rails g graphql:mutation CreateUser
```

案内に従って以下を追記

app/graphql/mutations/create_user.rb

```ruby:create_user.rb
module Mutations
  class CreateUser < BaseMutation
    field :user, Types::UserType, null: true

    argument :name, String, required: true
    argument :email, String, required: false

    def resolve(**args)
      user = User.create!(args)
      {
          user: user
      }
    end
  end
end
```

Update

```
$ docker-compose exec app rails g graphql:mutation UpdateUser
```

app/graphql/mutations/update_user.rb

```ruby:update_user.rb
module Mutations
  class UpdateUser < BaseMutation
    field :user, Types::UserType, null: true

    argument :id, ID, required: true
    argument :name, String, required: true
    argument :email, String, required: false

    def resolve(**args)
      user = User.find(args[:id])
      user.update!(name: args[:name], email: args[:email])
      {
          user: user
      }
    end
  end
end
```

Delete

```
$ docker-compose exec app rails g graphql:mutation DeleteUser
```

app/graphql/mutations/delete_user.rb

```ruby:delete_user.rb
module Mutations
  class DeleteUser < BaseMutation
    field :user, Types::UserType, null: true

    argument :id, ID, required: true

    def resolve(**args)
      user = User.find(args[:id])
      user.destroy!
      {
          user: user
      }
    end
  end
end
```

## Mutation Test

[http://localhost:3000/graphiql](http://localhost:3000/graphiql)へアクセスし、以下のクエリを投げる

```
mutation {
  createUser(
    input:{
      name: "Saburo Yamada"
      email: "yamada-saburo@test.com"
    }
  ){
    user {
      id
      name 
      email
    }
  }
}
```

```
mutation {
  updateUser(
    input:{
      id: 3
      name: "Sanshiro Yamada"
      email: "yamada-sanshiro@test.com"
    }
  ){
    user {
      id
      name 
      email
    }
  }
}
```

```
mutation {
  deleteUser(
    input:{
      id: 3
    }
  ){
    user {
      id
      name 
      email
    }
  }
}
```

## Settings for association

```
$ docker-compose exec app rails g model Post user:references
$ docker-compose exec app rails g model Label name:string post:references
$ docker-compose exec app rails db:migrate
$ docker-compose exec app rails c
$ Post.create(user: User.find(1))
$ Post.create(user: User.find(1))
$ Label.create(name: "LabelA", post: Post.find(1))
```

app/models/user.rb

```ruby:user.rb
class User < ApplicationRecord
  has_many :posts
end
```

app/models/post.rb
```ruby:post.rb
class Post < ApplicationRecord
  belongs_to :user
  has_one :label
end
```

app/models/label.rb
```ruby:label.rb
class Label < ApplicationRecord
  belongs_to :post
end
```

追記

app/graphql/types/post_type.rb
```ruby:post_type.rb
module Types
  class PostType < Types::BaseObject
    field :id, ID, null: false
    field :user_id, Integer, null: false
    # 追記
    field :label, LabelType, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
```

app/graphql/types/query_type.rb 
```ruby:query_type.rb
# 追記
field :posts, [Types::PostType], null: false
def posts
  Post.all
end
```

[http://localhost:3000/graphiql](http://localhost:3000/graphiql)へアクセスし、以下のクエリを投げる

```
{
  posts {
    id
    label {
      id
      name
    }
  }
}
```

追記

app/graphql/types/user_type.rb
```
field :posts, [PostType], null: true
```

[http://localhost:3000/graphiql](http://localhost:3000/graphiql)へアクセスし、以下のクエリを投げる

```
{
  user(id: 1) {
    id
    posts {
      id
      label {
        id
        name
      }
    }
  }
}
```

ここまででだいたいのことが実現できるが、このままだとN+1問題が発生する

## Resolve the N + 1

add gem
```
gem 'graphql-batch'
```

```
$ docker-compose exec app bundle i
```

app/graphql/rails_graphql_schema.rb 
```ruby:rails_graphql_schema.rb
class RailsGraphqlSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
  # 追記
  use GraphQL::Batch

  # 省略
end
```

Create Loader()

```
$ mkdir app/graphql/loaders
$ touch app/graphql/loaders/association_loader.rb
```

app/graphql/loaders/association_loader.rb

```ruby:association_loader.rb
module Loaders
  class AssociationLoader < GraphQL::Batch::Loader
    def self.validate(model, association_name)
      new(model, association_name)
      nil
    end

    def initialize(model, association_name)
      super()
      @model = model
      @association_name = association_name
      validate
    end

    def load(record)
      raise TypeError, "#{@model} loader can't load association for #{record.class}" unless record.is_a?(@model)
      return Promise.resolve(read_association(record)) if association_loaded?(record)

      super
    end

    # We want to load the associations on all records, even if they have the same id
    def cache_key(record)
      record.object_id
    end

    def perform(records)
      preload_association(records)
      records.each { |record| fulfill(record, read_association(record)) }
    end

    private

    def validate
      return if @model.reflect_on_association(@association_name)

      raise ArgumentError, "No association #{@association_name} on #{@model}"
    end

    def preload_association(records)
      ::ActiveRecord::Associations::Preloader.new.preload(records, @association_name)
    end

    def read_association(record)
      record.public_send(@association_name)
    end

    def association_loaded?(record)
      record.association(@association_name).loaded?
    end
  end
end
```

app/graphql/types/query_type.rb  

```ruby:query_type.rb
module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :email, String, null: true
    # 修正
    field :posts, [Types::PostType], null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # 追記
    def posts
      Loaders::AssociationLoader.for(User, :posts).load(object)
    end
  end
end

```
