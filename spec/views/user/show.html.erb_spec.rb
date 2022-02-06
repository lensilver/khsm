require 'rails_helper'

RSpec.describe 'users/show', type: :view do

  context 'when authenticated user viewing others page' do
    before(:each) do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'Миша'))
      stub_template 'users/_game.html.erb' => 'User game goes here'
      render
    end

    it 'renders player names' do
      expect(rendered).to match 'Миша'
    end

    it 'does not show edit button' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'renders game' do
      render partial: 'users/game'
      expect(rendered).to match 'User game goes here'
    end
  end

  context 'when authenticated user viewing his page' do
    let(:user) { FactoryBot.create(:user, name: 'Вадик') }
    before do
      assign(:user, user)
      sign_in user
      render
    end

    it 'renders user name' do
      expect(rendered).to match 'Вадик'
    end

    it 'show edit button' do
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end
end