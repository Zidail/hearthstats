require 'spec_helper'

describe 'dashboard' do
  it 'should load if logged in' do
    sign_in_int
    page.should have_content 'Dashboard'
  end
end
