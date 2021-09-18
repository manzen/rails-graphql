module Types
  class MutationType < Types::BaseObject
    field :delete_user, mutation: Mutations::DeleteUser
    field :update_user, mutation: Mutations::UpdateUser
    field :create_user, mutation: Mutations::CreateUser
  end
end
