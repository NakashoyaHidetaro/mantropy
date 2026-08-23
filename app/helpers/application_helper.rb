module ApplicationHelper
  def title
    @title # rubocop:disable Rails/HelperInstanceVariable
  end

  def login(param = nil)
    param.to_s
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
