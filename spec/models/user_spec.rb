require "rails_helper"

RSpec.describe User do
  describe "roles" do
    it "defaults to member" do
      expect(build(:user).role).to eq("member")
    end

    it "rejects an unknown role at the database level, not just in the model" do
      user = create(:user)

      expect {
        user.update_column(:role, "superuser")
      }.to raise_error(ActiveRecord::StatementInvalid, /users_role_known/)
    end
  end

  describe "registration requirements" do
    it "requires a name" do
      expect(build(:user, name: "")).not_to be_valid
    end

    it "requires acceptance of the terms on create" do
      expect(build(:user, terms_accepted_at: nil)).not_to be_valid
    end
  end

  describe "#can_download?" do
    let(:genre) { create(:genre) }
    let(:track) { create(:track, genre: genre) }

    it "is false for a visitor with no account" do
      expect(User.new.can_download?(track)).to be(false)
    end

    it "is false without a subscription" do
      expect(create(:user).can_download?(track)).to be(false)
    end

    it "is false when the subscription is not active" do
      user = create(:user)
      create(:subscription, user: user, plan: create(:plan), status: "incomplete")

      expect(user.can_download?(track)).to be(false)
    end

    it "is false when the genre is not entitled" do
      user = create(:user)
      subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 3))
      create(:genre_entitlement, subscription: subscription, genre: create(:genre))

      expect(user.can_download?(track)).to be(false)
    end

    it "is true when active and entitled" do
      user = create(:user)
      subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
      create(:genre_entitlement, subscription: subscription, genre: genre)

      expect(user.can_download?(track)).to be(true)
    end

    it "is false for a track marked not downloadable" do
      user = create(:user)
      subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
      create(:genre_entitlement, subscription: subscription, genre: genre)
      blocked = create(:track, genre: genre, downloadable: false)

      expect(user.can_download?(blocked)).to be(false)
    end

    it "is false for a draft track even when entitled" do
      user = create(:user)
      subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
      create(:genre_entitlement, subscription: subscription, genre: genre)
      draft = create(:track, :draft, genre: genre)

      expect(user.can_download?(draft)).to be(false)
    end
  end

  describe "#anonymize!" do
    it "erases personal data but keeps the licence history" do
      user = create(:user, name: "Real Person")
      subscription = create(:subscription, :active, user: user, plan: create(:plan))
      track = create(:track)
      TrackDownload.create!(user: user, track: track, license_terms_version: "v1")

      user.anonymize!

      expect(user.reload.email).to include("deleted+")
      expect(user.name).to eq("Deleted member")
      expect(user.encrypted_password).to be_blank
      expect(user.track_downloads.count).to eq(1)
      expect(user.subscriptions).to include(subscription)
    end
  end
end
