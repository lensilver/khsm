# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do

  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  describe 'testing game status' do
    # тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3})
    end

    it 'correct .answer_correct?' do
      # именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be(true)
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  describe '#add_audience_help' do
    it 'returns empty key before use' do
      expect(game_question.help_hash).not_to include(:audience_help)
    end  

    context 'when help of audience is used' do
      before {game_question.add_audience_help}
      
      it 'include added key after use' do
        expect(game_question.help_hash).to include(:audience_help)
      end

      it 'includes valid answers key'do
        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end
  end

  # тест на наличие методов делегатов level и text
  describe '#level & #text' do
    it 'returns correct level & .text' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end  
  end

  describe '#correct_answer_key' do
    it 'returns correct answer key' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  describe '#help_hash'do
    it 'returns empty hash at the start game' do
      expect(game_question.help_hash).to eq({})
    end

    it 'fills the hash' do
      game_question.help_hash[:audience_help] = 'true'
      expect(game_question.save).to be(true)
      expect(game_question.help_hash).to eq({audience_help: 'true'})
    end
  end

  describe '#add_audience_help' do
    it 'returns empty key before use' do
      expect(game_question.help_hash).not_to include(:audience_help)
    end

    context 'when help of audience is used' do
      before { game_question.add_audience_help }

      it 'include added key after use' do
        expect(game_question.help_hash).to include(:audience_help)
      end

      it 'includes valid answers key' do
        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end
  end

  # проверяем работу 50/50
  describe '#add_fifty_fifty' do
    it 'correct fifty_fifty' do
      # сначала убедимся, в подсказках пока нет нужного ключа
      expect(game_question.help_hash).not_to include(:fifty_fifty)
      # вызовем подсказку
      game_question.add_fifty_fifty

      # проверим создание подсказки
      expect(game_question.help_hash).to include(:fifty_fifty)
      ff = game_question.help_hash[:fifty_fifty]

      expect(ff).to include('b') # должен остаться правильный вариант
      expect(ff.size).to eq 2 # всего должно остаться 2 варианта
    end
  end

  describe '#add_friend_call' do
    context 'before using friend_call' do
      it 'the hash has empty key before use' do
        expect(game_question.help_hash).not_to include(:friend_call)
      end
    end

    context 'when call a friend is used' do    
      before { game_question.add_friend_call }
      let(:fc) { game_question.help_hash[:friend_call] }

      it 'adds key after use' do
        expect(game_question.help_hash).to include(:friend_call)
      end

      it 'displays correct text in the hash of the hint' do
        expect(fc.class).to be (String)
        expect(fc).to include('считает, что это вариант')
      end

      it 'passes one of the keys' do
        expect(fc).to match(/[ABCD]/)
      end
    end
  end
end
