module ApplicationHelper
  def title
    @title # rubocop:disable Rails/HelperInstanceVariable
  end

  def login(param = nil)
    param.to_s
  end

  # 必須項目用のラベル。ラベル文字列の後ろに赤い * を付ける
  def required_label(form, attribute, text)
    form.label attribute, class: 'form-label' do
      safe_join([text, ' ', tag.span('*', class: 'text-danger')])
    end
  end

  # フォーム冒頭に置く「* は必須項目です」の凡例
  def required_legend
    tag.p(safe_join([tag.span('*', class: 'text-danger'), ' は必須項目です']), class: 'form-text')
  end

  def serie_to_amazon_url(serie)
    serie = serie.books.order(publicationdate: :desc).first
    if serie&.detailurl
      serie.detailurl.gsub('kumantropy-22', 'mantropy-22').gsub('mantropy-22',
                                                                'kumantropy-22')
    else
      '/'
    end
  end
end
