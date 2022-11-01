# frozen_string_literal: true

class V12Customer < V12Object
  attr_accessor :fname
  attr_accessor :lname
  attr_accessor :email
  attr_accessor :mob_tele
  attr_accessor :home_tele

  def initialize(fname, lname, email, mob_tele, home_tele)
    @fname = fname
    @lname = lname
    @email = email
    @mob_tele = mob_tele
    @home_tele = home_tele
  end

  def to_hash
    {
      'FirstName': @fname,
      'LastName': @lname,
      'EmailAddress': @email,
      'HomeTelephone': { 'Code': @home_tele[0..4], 'Number': @home_tele[5..10] },
      'MobileTelephone': { 'Code': @mob_tele[0..4], 'Number': @mob_tele[5..10] }
    }
  end
end
