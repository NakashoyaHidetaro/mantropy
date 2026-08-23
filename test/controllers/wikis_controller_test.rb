require 'test_helper'

class WikisControllerTest < ActionDispatch::IntegrationTest
  test '存在しないWikiページの場合はリダイレクトされる' do
    get wiki_path(name: 'nonexistent_wiki')
    assert_redirected_to root_path
  end

  test '公開WikiページにはXへの共有ボタンが表示される' do
    get wiki_path(name: wikis(:one).name)
    assert_response :success
    assert_select 'a[href^="https://x.com/intent/post"]'
  end

  test '内部限定Wikiページにはログインしていても共有ボタンが表示されない' do
    sign_in userauths(:one)
    get wiki_path(name: wikis(:private_wiki).name)
    assert_response :success
    assert_select 'a[href^="https://x.com/intent/post"]', count: 0
  end
end
