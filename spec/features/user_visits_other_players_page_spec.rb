require 'rails_helper'

RSpec.feature 'USER sees profile the other player', type: :feature do
  let(:user1) { create(:user, name: 'John Doe', id: 1)}
  let(:user2) { create(:user, name: 'Jane Doe', id: 2)}

  let!(:games) do
  	[create(:game, user: user2, created_at: Time.zone.parse('2021.02.07, 13:00'), current_level: 14, prize: 500000),
     create(:game, user: user2, created_at: Time.zone.parse('2021.02.07, 14:00'), finished_at: Time.zone.parse('2021.02.07, 14:20'), current_level: 14, prize: 500000)]
  end

  before do
	login_as user1
  end

  scenario 'Jone Doe sees profile of Jane Doe' do

    visit "/"
    click_link 'Jane Doe'
    save_and_open_page

    expect(page).to have_content '07 февр., 13:00'
    expect(page).to have_content '07 февр., 14:00'
    expect(page).to have_content 'John Doe'
    expect(page).to have_content 'Jane Doe'
    expect(page).to have_content '14'
    expect(page).to have_content '500 000 ₽'
    expect(page).to have_content 'в процессе'
    expect(page).to have_content 'деньги'
    expect(page).not_to have_content 'Сменить имя и пароль'
   end
end
