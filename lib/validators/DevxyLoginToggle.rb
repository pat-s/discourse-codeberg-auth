# frozen_string_literal: true

class ValidateDevxyToggle
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(val)
    return true unless SiteSetting.enable_devxy_login?

    !val.empty?
  end

  def error_message
    I18n.t('discourse_devxy_auth.errors.cannot_remove')
  end
end
