# frozen_string_literal: true

module C
  module PaymentMethod
    class V12Finance < ApplicationRecord
      include Payable

      class UnknownFinanceOption < RuntimeError
      end

      FinanceStruct = Struct.new(:name, :id, :guid)

      FINANCE_OPTIONS = [
        FinanceStruct.new('Roland Interest Free Finance (6 Months)',
                          349,
                          '240810C7-199C-453D-BE09-A6E1916EBD1A'),
        FinanceStruct.new('Take it away Under 18 Interest Free (9 Months)',
                          248,
                          '274CC4BD-76CA-4BE3-AE28-9B793A6AC766'),
        # FinanceStruct.new('Roland Interest Free Finance (9 Months)',
        # 234,
        # 'CA75F0F0-C5B7-46DA-9421-F8146D9A2E29'),
        FinanceStruct.new('Take it away Interest Free (9 Months)',
                          245,
                          '7ABD052A-D2DD-47C6-AAA0-C59F88316CE9'),
        FinanceStruct.new('Interest Free Finance 6 Months',
                          27,
                          '244B3E7A-0FFB-41F2-88D5-ADF78B6A3D9E'),
        FinanceStruct.new('Interest Free Finance (9 Months)',
                          43,
                          '20125E19-F2C2-42F4-A230-EC668F776296'),
        FinanceStruct.new('Interest Free Finance (12 Months)',
                          28,
                          '8E0BD3A9-657F-457C-B488-DBFAB37FAC39'),
        FinanceStruct.new('Interest Free Finance (18 Months)',
                          46,
                          'C3114266-125A-4EA1-AB10-CFB3EBD48B81'),
        # FinanceStruct.new('Take it away Interest Free (18 Months)',
        # 246,
        # 'BDB1F954-6079-46D9-920D-F4DF7DC54921'),
        # FinanceStruct.new('Take it away Under 18 Interest Free (18 Months)',
        # 249,
        # 'A36654A4-7ECF-43F1-97B5-F887B0C4F0F0'),
        # FinanceStruct.new('Roland Interest Free Finance (24 Months)',
        # 238,
        # '9BE314F3-E47B-4BF9-9676-9C8132BA81C5'),
        FinanceStruct.new('Interest Free Finance (24 Months)',
                          29,
                          '9D6FA148-EEB2-4345-B5C6-961902A8F0EB'),
        FinanceStruct.new('Interest Free Finance (36 Months)',
                          30,
                          'E931AB43-B8AE-431D-AC50-812D413FB5BB'),
        # FinanceStruct.new('Interest Free Finance (48 Months)',
        # 31,
        # 'E2D7B26B-D494-494A-AA50-A804C52942A0'),
        # FinanceStruct.new('Roland Interest Bearing Finance (36 Months 3.9%)',
        # 239,
        # 'DF496594-BE6D-4340-849A-D4719C354F01'),
        FinanceStruct.new('Classic Credit 9 months 4.9%',
                          145,
                          '7C31835B-D7FF-470B-86BF-4C772B3F24E1'),
        FinanceStruct.new('Classic Credit 12 months 4.9%',
                          146,
                          'AEDA558E-5406-4CF3-B05C-39EB57B19E37'),
        FinanceStruct.new('Classic Credit 18 months 4.9%',
                          147,
                          '5FDC06BB-ED0B-4365-9ECA-3B4C6C489DD6'),
        FinanceStruct.new('Classic Credit 24 Months 4.9%',
                          118,
                          'B30BDB3C-DECA-460F-9A49-6F67642DA395'),
        FinanceStruct.new('Classic Credit 36 Months 4.9%',
                          119,
                          'E35912B4-CB1B-40EF-A4F9-2E14B60901D4'),
        # FinanceStruct.new('Classic Credit 48 months 4.9%',
        # 149,
        # '5C26BFD2-544C-4469-80E1-1324AA151360'),
        FinanceStruct.new('Classic Credit 12 months 9.9%',
                          162,
                          '46AFF7E0-910C-4F4D-8D36-4BC3E2A84DAD'),
        FinanceStruct.new('Classic Credit 24 Months 9.9%',
                          54,
                          '152FEA32-BE31-4B73-94D9-F23716C42AAC'),
        FinanceStruct.new('Classic Credit 36 Months 9.9%',
                          44,
                          'CC62BB86-F91B-4A85-97EB-94BB7AC4462F'),
        # FinanceStruct.new('Classic Credit 48 Months 9.9%',
        # 45,
        # '5C0DA208-597B-4DC8-9E42-2326601FA699'),
        # FinanceStruct.new('Classic Credit 12 Months 15.9%',
        # 112,
        # 'BED9D208-D9C1-4D8E-A29F-DECB53FD0B22'),
        # FinanceStruct.new('Classic Credit 24 Months 15.9%',
        # 64,
        # '1401BD54-9A22-4CE7-8F7C-61A3EBB93639'),
        # FinanceStruct.new('Classic Credit 36 Months 15.9%',
        # 65,
        # 'BBE76DA6-C60E-4881-83FC-328E415F0A5A'),
        # FinanceStruct.new('Classic Credit 48 Months 15.9%',
        # 66,
        # '3FD9BCDE-BC26-47D2-BD4F-DF453BC6F1A1'),
        # FinanceStruct.new('Classic Credit 12 Months 19.9%',
        # 16,
        # 'EAA79F8C-7E34-4271-9DF0-05E31799E90F'),
        # FinanceStruct.new('Classic Credit 18 months 19.9%',
        # 201,
        # 'F9D6DF15-886C-40EE-8B1E-25BA930B383B'),
        # FinanceStruct.new('Classic Credit 24 Months 19.9%',
        # 217,
        # '69F15799-5FC9-496D-925D-622958ACD83D'),
        # FinanceStruct.new('Classic Credit 36 Months 19.9%',
        # 18,
        # '8FBCDE88-3687-4721-A9D3-6F73F69A6757'),
        # FinanceStruct.new('Buy Now Pay Later (12 Months/36) 19.9%',
        # 275,
        # '9939C382-B6C3-476A-A973-0794387FB54F'),
        # FinanceStruct.new('Buy Now Pay Later (9 Months / 39) 19.9%',
        # 269,
        # '54CB81B3-BBB5-4745-A7A8-81F4A5CC34A0'),
        # FinanceStruct.new('Buy Now Pay Later (6/42) 19.9%',
        # 125,
        # '796D6BBE-E177-4E46-89E6-24EA2A24461F'),
        # FinanceStruct.new('Classic Credit 48 Months 19.9%',
        # 26,
        # '31A50441-CE76-4520-BB42-5E5B72949FBC')
      ].freeze

      enum last_status: %i[
        error acknowledged referred declined accepted
        awaiting_fulfilment payment_requested payment_processed cancelled
      ]

      def finalize!(user_params = {})
        current_status = update_status!

        %i[accepted awaiting_fulfilment].include?(current_status)
      end

      def update_status!
        status = current_application.status

        update(last_status: status)
        status
      end

      def paid?
        current_status = update_status!

        %i[accepted awaiting_fulfilment payment_requested
           payment_processed].include?(current_status)
      end

      def cancel!
        application = current_application
        raise unless application.cancel
      end

      def off_site_confirmation?
        true
      end

      def self.find_finance_option(id)
        FINANCE_OPTIONS.select { |v| v.id == id }.first
      end

      def transaction_id
        application_guid
      end

      private

      def current_application
        V12Application.new(
          id: application_id,
          retailer: V12Retailer.new(
            ENV['V12_ID'],
            ENV['V12_GUID'],
            ENV['V12_AUTH_TOKEN']
          )
        )
      end
    end
  end
end
