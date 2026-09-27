require 'test_helper'

class Member::Series::MagazineSeriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @serie = series(:one)
    sign_in @userauth
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    patch member_serie_magazine_serie_path(@serie)
    assert_redirected_to new_userauth_session_path
  end

  test '雑誌が特定できない場合は500にならずエラーつきで編集画面へ戻される' do
    assert_no_difference 'MagazinesSerie.count' do
      patch member_serie_magazine_serie_path(@serie),
            params: { mode: 'add', magazine_name: '', magazine_id: '', magazine_placed: '' }
    end
    assert_redirected_to edit_member_serie_path(@serie)
    assert flash[:alert].present?
  end

  test '掲載誌を追加できる' do
    assert_difference 'MagazinesSerie.count', 1 do
      patch member_serie_magazine_serie_path(@serie),
            params: { mode: 'add', magazine_name: '新雑誌', magazine_id: '', magazine_placed: '2020年' }
    end
    assert_redirected_to edit_member_serie_path(@serie)
  end
end
