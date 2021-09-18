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
