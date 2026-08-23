Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  get 'up' => 'rails/health#show', as: :rails_health_check

  # ============================================
  # Devise
  # ============================================
  devise_for :userauths, controllers: { registrations: 'userauths/registrations' }

  # ============================================
  # Public（認証不要）
  # ============================================
  root 'homes#index'
  get '/robots' => 'homes#robots'

  resources :users, only: %i[index show], param: :name

  # 旧シリーズURL（/:name/series/:id と /series/:id）の互換用リダイレクト。
  # 現在の正規URLは public_id を使う /series/:public_id だが、
  # 過去に公開していた数値ID形式のURLを 301 で新URLへ転送する。
  # public_id は16桁の英数字なので純粋な数値と衝突しないが、
  # constraints で数値のみを legacy_show に振り分けることを担保している。
  # resources :series より先に定義する必要がある。
  get '/:name/series/:id', to: 'series#legacy_show', constraints: { id: /\d+/ }
  get '/series/:id', to: 'series#legacy_show', constraints: { id: /\d+/ }
  resources :series, only: %i[index show], param: :public_id

  resources :rankings, only: %i[index] do
    scope module: :rankings do
      resources :series, only: %i[index] do
        get :aggregated, on: :collection
      end
    end
  end

  resources :wikis, only: %i[show], param: :name

  # ============================================
  # Member（認証必須）
  # ============================================
  namespace :member do
    root 'homes#index'

    resources :posts, only: %i[index create]
    resources :ranks, only: %i[create destroy]

    resources :topics, only: %i[index new create edit update]
    # オプショナルセグメント（範囲指定・top指定）を含むため resources では表現できないので生ルートで維持する
    get '/topics/:id(/((:from)(-:to))(/:top))' => 'topics#show',
        as: :topic_show, constraints: { id: /\d+/ }

    resources :wikis, only: %i[index new create edit update destroy]
    resources :users, only: %i[new create edit update], param: :name

    resources :series, only: %i[new create edit update], param: :public_id do
      scope module: :series do
        resource :author, only: %i[update]
        resource :magazine_serie, only: %i[update]
        resource :post, only: %i[update]
      end
    end

    resources :rankings, only: %i[index create update]
  end
end
