require 'csv'


class Database_manager
    def initialize
        File.open("user_data.csv", 'r') do |f|
            @data = f.read
            @data = @data.split('\n')
        end
    end



    def add_row(inp_array)
        new_row = inp_array.join(',')
        @data.push(new_row)

        update
    end

    def delete_row(atm_num)
        del_row = ""
        @data.each do |row|
            if row.split(",")[2].to_i == atm_num.to_i
                del_row = row
            end
        end
        @data.delete(del_row)
        update
    end

    def exists?(atm_num)
        @data.each do |row|
            if row.split(",")[2].to_i == atm_num.to_i
                return [true, row]
            end
        end
        return [false, ""]
    end

    def update_info(atm_number, name, pin, balance)
        @data.each.with_index do |row, index|
            if row.split(",")[2].to_i == atm_number.to_i
                old_row = @data[index].split(",")
                new_row = [old_row[0], name, old_row[2], pin, old_row[4], balance].join(",")
                @data[index] = new_row
            end
        end
        update
    end


    private
    def update
        File.open("user_data.csv", 'w') do |f|
            f.write(@data.join('\n'))
            # p @data
        end
    end

end


class UserAccount
    @@total_users = 0
    @@counter = 0
    def initialize(name, atm_number, pin, expiry_date, balance, db)

        exists = db.exists?(atm_number)
        if exists[0]
            row_data = exists[1].split(',')

            @id = row_data[0].to_i
            @name = row_data[1]
            @atm_number = row_data[2].to_i
            @pin = row_data[3].to_i
            @expiry_date = row_data[4]
            @balance = row_data[5].to_i
            @db = db

            return
        end


        @name = name
        @atm_number = atm_number.to_i
        @pin = pin.to_i
        @expiry_date = expiry_date
        @balance = balance.to_i

        @@total_users += 1
        @@counter += 1

        @id = @@counter

        db.add_row([@id, @name, @atm_number, @pin, @expiry_date, @balance])

    end

    def change_pin(current_pin, new_pin, confirm_new_pin)
        if correct_pin?(current_pin)
            if new_pin.to_i == confirm_new_pin.to_i
                @pin = new_pin.to_i
            else
                puts "Your entered new pins don't match. Try again!"
            end
        else
            puts "Then pin you entered is incorrect. Try again!"
        end
        update
    end

    def get_id
        @id
    end

    def get_atm_number
        @atm_number
    end

    def change_name(current_pin, new_name)
        if correct_pin?(current_pin)
            @name = new_name
        else
            puts "Then pin you entered is incorrect. Try again!"
        end
        update
    end

    def show_balance
        puts "The account balance of #{@name} is #{@balance}"
    end

    def withdraw_cash(pin, amount)
        amount = amount.to_i
        if !correct_pin?(pin)
            puts "The pin you entered is incorrect. Try again!"
            return
        end

        if amount > @balance.to_i
            puts "Your account balanace is insufficient for this transaction. Please rty again"
        else
            @balance -= amount
            puts "Rupees #{amount} have been debited from your account. Your new account balance is #{@balance}."
        end
        update
    end

    def delete_user(pin, user_obj)
        # delete from csv
        if correct_pin?(pin) == false
            puts "Please enter the correct pin and Try again!"
            return false
        end

        @@total_users -= 1

        @db.delete_row(user_obj.get_atm_number.to_i)

        puts "Your account has been deleted successfully."
        return true

    end


    
    def correct_pin?(pin)
        if pin.to_i == @pin.to_i
            true
        else
            false
        end
    end

    private
    def update
        @db.update_info(@atm_number, @name, @pin, @balance)
    end

end


class Machine
    def initialize(id, location, cash_available, db)
        @id = id
        @location = location
        @cash_available = cash_available
        @db = db
        @logged_in = nil
        @pin = nil
        @db = db
    end

    def login(atm_number, pin)
        if @db.exists?(atm_number)[0]
            usr = UserAccount.new("", atm_number, 0, "", 0, @db)
            if usr.correct_pin?(pin)
                @logged_in = usr
                @pin = pin
                puts "You have successfully logged in."
            else
                puts "Please try again with correct pin."
            end
        else
            puts "No user exists with these credentials. Please try again."
        end
    end

    def logout
        @logged_in = nil
        @pin = nil
        puts "You have successfully logged out of your account."
    end

    def show_user_balance
        if !@logged_in
            puts "Please login to view your balance."
            return
        end
        @logged_in.show_balance
    end

    def withdraw_user_cash(amount)
        if @logged_in
            if amount.to_i < @cash_available.to_i
                @logged_in.withdraw_cash(@pin, amount)
            else
                puts "Not enough cash in machine. Please try again."
            end
        else
            puts "Please login to withdraw cash."
        end
    end

    def get_logged_in_user
        @logged_in
    end

end



# File.open("user_data.csv", 'w') do |f|
#     f.write("")
#


def main
    quit = false

    menu = "
    0) Quit
    1) Login
    2) Logout
    3) Create new account
    4) Update account name
    5) Update account pin
    6) Withdraw cash
    7) Show balance
    8) Delete account
    "
    db = Database_manager.new
    machine = Machine.new(0, "Bhatta chowk", 100000, db)

    usr = UserAccount.new("Amy", 1234, 1234, "11/11/2011", 1000, db)
    usr1 = UserAccount.new("Robert", 3456, 1234, "11/11/2011", 100, db)
    usr2 = UserAccount.new("Emma", 4567, 1234, "11/11/2011", 10000, db)

    while !quit
        puts "\n\nMAIN INTERFACE"
        puts menu

        puts "Please enter your choice:"
        input = gets.chomp

        if input.to_i == 0
            break

        elsif input.to_i == 1
            if machine.get_logged_in_user
                puts "a user is already logged in. Please logout first."
                next
            end
            puts "Please enter your atm number:"
            atm_num = gets.chomp
            puts "Please enter your pin:"
            pin = gets.chomp
            machine.login(atm_num, pin)

        elsif input.to_i == 2
            if !machine.get_logged_in_user
                puts "Please login first to logout."
                next
            end
            machine.logout

        elsif input.to_i == 3
            puts "Create new account interface"
            puts "Please enter the name for your account: "
            name = gets.chomp
            
            puts "Please enter your ATM number:"
            atm_number = gets.chomp

            exists = db.exists?(atm_number)

            if exists[0]
                puts "An account already exists with this atm number. Please try again."
                next
            end

            puts "Please enter a pin for your account:"
            pin = gets.chomp

            puts "Please re-enter the pin for confirmation:"
            confirm_pin = gets.chomp

            puts "Please enter an expiry date in the format DD/MM/YYYY:"
            expiry_date = gets.chomp

            puts "Please enter your balance:"
            balance = gets.chomp

            UserAccount.new(name, atm_number, pin, expiry_date, balance, db)
            puts "Your account has been created. Please login to start using your account."

        elsif input.to_i == 4
            if !machine.get_logged_in_user
                puts "Please login first to update your account information."
                next
            end
            puts "Please enter your pin to confirm your identity: "
            pin = gets.chomp
            puts "Please enter your new name: "
            name = gets.chomp
            machine.get_logged_in_user.change_name(pin, name)

        elsif input.to_i == 5
            if !machine.get_logged_in_user
                puts "Please login first to update your account information."
                next
            end

            puts "Please enter your pin to confirm your identity: "
            pin = gets.chomp
            puts "Please enter your new pin: "
            new_pin = gets.chomp
            puts "Please confirm your new pin and re-enter it:"
            confirm_pin = gets.chomp

            machine.get_logged_in_user.change_pin(pin, new_pin, confirm_pin)


        elsif input.to_i == 6
            if !machine.get_logged_in_user
                puts "Please login first to withdraw cash."
                next
            end
            
            puts "Please enter the amount you want to withdraw:"
            amount = gets.chomp
            machine.withdraw_user_cash(amount)


        elsif input.to_i == 7
            machine.show_user_balance

        elsif input.to_i == 8
            if !machine.get_logged_in_user
                puts "Please login to delete a user."
                next
            end

            puts "Please enter your pin to confirm your identity: "
            pin = gets.chomp

            if machine.get_logged_in_user.delete_user(pin, machine.get_logged_in_user)
                machine.logout
            end
        
        else
            puts "Please enter a valid option and try again."
        end

        puts "\n\n"


    end

end

main

# db = Database_manager.new
# db.update_info(4567, "Emily", 4444, 20000)


