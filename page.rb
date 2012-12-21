
class Page

  COUNT_OF_ENTRIES = 10

  def initialize current_page, count_of_records
    @current = current_page
    @next = self.last?(count_of_records) ? nil : @current + 1
    @prev = @current > 1 ? @current -1 : nil
  end

  attr_reader :current, :next, :prev

  def last? count_of_records
    @current == (count_of_records / COUNT_OF_ENTRIES).ceil
  end
end
