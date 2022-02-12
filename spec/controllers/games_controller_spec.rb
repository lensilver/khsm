require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { create(:user) }
  # админ
  let(:admin) { create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '#answer' do
    context 'when an unregistered user answers a question ' do
      it 'kick from #answer to sign in page' do
        put :answer, id: game_w_questions.id, letter: 'a'

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when a registered user gives wrong answer' do
      before { sign_in user }

      it 'returns status of the game & right routes' do
        put :answer, id: game_w_questions.id, letter: 'a'
        game = assigns(:game)

        expect(game.finished?).to be true
        expect(game.status).to eq(:fail)
        expect(response).to redirect_to(user_path(user))
        expect(flash[:alert]).to be
      end
    end

    context 'when a registered user answers correctly and continues the game' do
      before { sign_in user }
      
      it 'continues the game before answer' do
        # передаем параметр params[:letter]
        put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
        game = assigns(:game)

        expect(game.finished?).to be false
        expect(game.current_level).to be > 0
        expect(response).to redirect_to(game_path(game))
        expect(flash.empty?).to be true # удачный ответ не заполняет flash
      end
    end
  end

  describe '#create'do
    context 'when an unregistered user create a new game' do
      it 'kick from #create to sign in page' do
        post :create, id: game_w_questions.id

        expect(response.status).not_to eq(200) 
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be 
      end
    end

    context 'when a user tries to open another user`s game' do
      before { sign_in user }
            
      it '#show alien game' do
        # создаем новую игру, юзер не прописан, будет создан фабрикой новый
        alien_game = create(:game_with_questions)

        # пробуем зайти на эту игру текущий залогиненным user
        get :show, id: alien_game.id

        expect(response.status).not_to eq(200) # статус не 200 ОК
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be # во flash должен быть прописана ошибка
      end
    end

    context 'when the user cannot start a new game without finishing the previous one' do
      before { sign_in user }
      
      it 'try to create second game' do
        expect(game_w_questions.finished?).to be false

        # отправляем запрос на создание, убеждаемся что новых Game не создалось
        expect { post :create }.to change(Game, :count).by(0)

        game = assigns(:game) # вытаскиваем из контроллера поле @game
        expect(game).to be_nil

        # и редирект на страницу старой игры
        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash[:alert]).to be
      end
    end

    context 'when a registered user creates a new game' do
      before { sign_in user }
      
      it 'creates game' do
        # сперва накидаем вопросов, из чего собирать новую игру
        generate_questions(15)

        post :create
        game = assigns(:game) # вытаскиваем из контроллера поле @game

        # проверяем состояние этой игры
        expect(game.finished?).to be false
        expect(game.user).to eq(user)
        # и редирект на страницу этой игры
        expect(response).to redirect_to(game_path(game))
        expect(flash[:notice]).to be
      end
    end
  end

  describe '#help' do
    context 'when the user uses audience help' do
      before { sign_in user }

      it 'returns empty key' do
        # сперва проверяем что в подсказках текущего вопроса пусто
        expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
        expect(game_w_questions.audience_help_used).to be false
      end

      it 'recorded a hint, the game continues' do        
        put :help, id: game_w_questions.id, help_type: :audience_help
        game = assigns(:game)

        # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
        expect(game.finished?).to be false
        expect(game.audience_help_used).to be true
        expect(game.current_game_question.help_hash[:audience_help]).to be
        expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        expect(response).to redirect_to(game_path(game))
      end
    end
  end

  describe '#take_money'do
    context 'when an unregistered user take money' do
      it 'kick from #take_money to sign in page' do
        put :take_money, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when the user takes the money until the end of the game' do
      before { sign_in user }

      it 'takes money' do
        # вручную поднимем уровень вопроса до выигрыша 200
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
        game = assigns(:game)

        expect(game.finished?).to be true
        expect(game.prize).to eq(200)

        # пользователь изменился в базе, надо в коде перезагрузить!
        user.reload
        expect(user.balance).to eq(200)

        expect(response).to redirect_to(user_path(user))
        expect(flash[:warning]).to be
      end
    end
  end

  describe '#show' do
    context 'when an unregistered user wants to watch the game' do
      it 'kick from #show to sign in page' do            
        get :show, id: game_w_questions.id
            
        expect(response.status).not_to eq(200) # статус не 200 ОК
        expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
        expect(flash[:alert]).to be # во flash должен быть прописана ошибка
      end
    end

    context 'when a registered user sees his game' do
      before { sign_in user }
      it 'displays game' do
        get :show, id: game_w_questions.id
        game = assigns(:game) # вытаскиваем из контроллера поле @game

        expect(game.finished?).to be false
        expect(game.user).to eq(user)
        expect(response.status).to eq(200) # должен быть ответ HTTP 200
        expect(response).to render_template('show') # и отрендерить шаблон show
      end
    end
  end
end
