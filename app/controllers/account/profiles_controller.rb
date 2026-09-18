module Account
  class ProfilesController < BaseController
    def show
      authorize member
    end

    def edit
      authorize member, :edit?
    end

    def update
      authorize member, :update?

      if member.update(profile_params)
        redirect_to account_profile_path, notice: "Your details were updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:name, :email)
    end
  end
end
