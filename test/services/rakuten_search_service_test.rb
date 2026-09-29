require 'test_helper'

class RakutenSearchServiceTest < ActiveSupport::TestCase
  # HTTPClient#get の呼び出し引数を記録するだけの偽クライアント
  class FakeHTTPClient
    Response = Struct.new(:body)

    attr_reader :calls

    def initialize(body)
      @body = body
      @calls = []
    end

    def get(*args)
      @calls << args
      Response.new(@body)
    end
  end

  test 'Itemsがある正常応答ではItemの配列を返す' do
    body = { 'Items' => [{ 'Item' => { 'title' => '作品A' } }, { 'Item' => { 'title' => '作品B' } }] }
    stub_singleton_method(RakutenSearchService, :query, body) do
      assert_equal [{ 'title' => '作品A' }, { 'title' => '作品B' }], RakutenSearchService.search('作品')
    end
  end

  test '旧形式のエラー応答ではerror_descriptionを含むApiErrorになる' do
    body = { 'error' => 'service_unavailable',
             'error_description' => 'BooksBook/Search/20170404 is under maintenance' }
    stub_singleton_method(RakutenSearchService, :query, body) do
      error = assert_raises(RakutenSearchService::ApiError) { RakutenSearchService.search('作品') }
      assert_includes error.message, 'BooksBook/Search/20170404 is under maintenance'
    end
  end

  test '新形式のエラー応答ではerrorMessageを含むApiErrorになる' do
    body = { 'errors' => { 'errorCode' => 400,
                           'errorMessage' => 'accessKey must be present as a query parameter or in the header' } }
    stub_singleton_method(RakutenSearchService, :query, body) do
      error = assert_raises(RakutenSearchService::ApiError) { RakutenSearchService.search('作品') }
      assert_includes error.message, 'accessKey must be present as a query parameter or in the header'
    end
  end

  test 'どちらの形式でもない応答では不正な応答としてApiErrorになる' do
    stub_singleton_method(RakutenSearchService, :query, {}) do
      error = assert_raises(RakutenSearchService::ApiError) { RakutenSearchService.search('作品') }
      assert_includes error.message, '不正な応答'
    end
  end

  test 'queryはAPI_POINTへapplicationIdとtitleを渡しaccessKeyヘッダ付きでGETする' do
    original_app_id = ENV.fetch('RAKUTEN_APP_ID', nil)
    original_access_key = ENV.fetch('RAKUTEN_ACCESS_KEY', nil)
    ENV['RAKUTEN_APP_ID'] = 'test-app-id'
    ENV['RAKUTEN_ACCESS_KEY'] = 'test-access-key'
    client = FakeHTTPClient.new('{"Items":[]}')

    result = stub_singleton_method(HTTPClient, :new, client) do
      RakutenSearchService.query('作品')
    end

    assert_equal({ 'Items' => [] }, result)
    assert_equal 1, client.calls.size
    url, query, header = client.calls.first
    assert_equal RakutenSearchService::API_POINT, url
    query = query.transform_keys(&:to_s)
    assert_equal 'test-app-id', query['applicationId']
    assert_equal '作品', query['title']
    header = header.transform_keys(&:to_s)
    assert_equal 'test-access-key', header['accessKey']
  ensure
    ENV['RAKUTEN_APP_ID'] = original_app_id
    ENV['RAKUTEN_ACCESS_KEY'] = original_access_key
  end
end
