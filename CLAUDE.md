## Coding Guidelines
* Mainly write logic on app/models/concerns/*.rb; Use "Fat Model, Skinny Controller" principle.
* Prefere "module functions"; where "module SomeModule; class << self; def some_method; end; end; end" style. Use a few instance methods for models.
* Create tests for app/models/concerns/*.rb in test/models/concerns/*.rb
* When adding a new Controller, you must add tests for it.
* View of MVC is written in `app/views/**/*.html.haml` .
* All comments and name of test cases should be written in Japanese, 日本語.
* ビジネス意味のある数値(件数、文字数上限、期間、タイムアウト、料金など)は、`.rb` / `.haml` 内にベタ書きせず、関連する `app/models/*.rb` または `app/models/concerns/*.rb` の先頭に `SCREAMING_SNAKE_CASE` 定数として定義し、利用側からは `Model::CONST` で参照する。
  * 対象外: `0` / `1` / `-1` などの制御フロー値、配列インデックス、`100` などのパーセント計算、HTTPステータスコード、enum 値、Bootstrap グリッド数や CSS / レイアウト用の数値。

## Testing Guidelines
* 画面上の文言やリンクの存在をアサートするだけのテストケースは書かない。文言変更のたびに壊れるだけで価値が薄い。
  * ただし、他の機能(認可・データスコープ・検索・分岐など)を検証するテストの中で、確認手段として文言やリンクをアサートするのはOK。

## After finished writing codes
* Please add some tests.
  * All comments and test case names should be written in Japanese.
* Always exec $ bundle exec rubocop -A; and $ bundle exec rails test;
  * Metrics/BlockLength, Metrics/AbcSize, Metrics/MethodLength, Metrics/ClassLength can be ignored if necessary. Add "rubocop:disable" comments after the method/class definition line.
  * rubocop can't check the Haml files; for Haml files, please check by bundle exec rails test.
