require 'unit_spec_helper'

describe Shoulda::Matchers::ActionController::CallbackMatcher, type: :controller do
  shared_examples 'CallbackMatcher' do |kind, callback_type|
    let(:kind) { kind }
    let(:callback_type) { callback_type }
    let(:method_name) { :authenticate_user! }
    let(:matcher) { described_class.new(method_name, kind, callback_type) }
    let(:controller) { define_controller('HookController').new }

    def match
      __send__("use_#{kind}_#{callback_type}", method_name)
    end

    it "matches when a #{kind} hook is in place" do
      add_callback(kind, callback_type, method_name)

      expect(controller).to match
    end

    it "does not match when a #{kind} hook is missing" do
      expect(controller).not_to match
    end

    describe 'description' do
      it 'includes the filter kind and name' do
        expect(matcher.description).to eq "have #{method_name.inspect} as a #{kind}_#{callback_type}"
      end
    end

    describe 'failure message' do
      it 'includes the filter kind and name that was expected' do
        message = "Expected that HookController would have #{method_name.inspect} as a #{kind}_#{callback_type}"

        expect {
          expect(controller).to send("use_#{kind}_#{callback_type}", method_name)
        }.to fail_with_message(message)
      end
    end

    describe 'failure message when negated' do
      it 'includes the filter kind and name that was expected' do
        add_callback(kind, callback_type, method_name)
        message = "Expected that HookController would not have #{method_name.inspect} as a #{kind}_#{callback_type}"

        expect { expect(controller).not_to match }.to fail_with_message(message)
      end
    end

    context "qualified with except" do
      let(:action) { :index }
      let(:multiple_actions) { [:index, :show] }
      let(:other_action) { :other_action }

      context "and when a #{kind} hook is in place with the qualifier" do
        it "accepts" do
          add_callback(kind, callback_type, method_name, except: action)
          expect(controller).to match.except(action)
        end

        it "accepts with multiple qualifier options" do
          add_callback(kind, callback_type, method_name, except: multiple_actions)
          expect(controller).to match.except(multiple_actions)
        end
      end

      context "and when a #{kind} hook is in place without the qualifier" do
        it "rejects" do
          add_callback(kind, callback_type, method_name)
          expect(controller).not_to match.except(action)
        end

        it "rejects with multiple qualifier options" do
          add_callback(kind, callback_type, method_name)
          expect(controller).not_to match.except(multiple_actions)
        end
      end

      context "and when a #{kind} hook is in place but the qualifier is on other action" do
        it "rejects" do
          add_callback(kind, callback_type, method_name)
          add_callback(kind, callback_type, other_action, except: action)
          expect(controller).not_to match.except(action)
        end

        it "rejects with multiple qualifier options" do
          add_callback(kind, callback_type, method_name)
          add_callback(kind, callback_type, other_action, except: multiple_actions)
          expect(controller).not_to match.except(multiple_actions)
        end
      end

      context "and when a #{kind} hook is missing" do
        it "rejects" do
          expect(controller).not_to match.except(action)
        end

        it "rejects with multiple qualifier options" do
          expect(controller).not_to match.except(multiple_actions)
        end
      end

      describe 'description' do
        it 'includes the filter kind and name and qualifier option' do
          message = "have #{method_name.inspect} as a #{kind}_#{callback_type} :except => [:#{action}]"
          expect(matcher.except(action).description).to eq(message)
        end
      end

      describe 'failure message' do
        it 'includes the filter kind name and qualifier that was expected' do
          message = "Expected that HookController would have #{method_name.inspect} as a #{kind}_#{callback_type} :except => [:#{action}]"

          expect {
            expect(controller).to match.except(action)
          }.to fail_with_message(message)
        end
      end

      describe 'failure message when negated' do
        it 'includes the filter kind and name that was expected' do
          add_callback(kind, callback_type, method_name, except: action)
          message = "Expected that HookController would not have #{method_name.inspect} as a #{kind}_#{callback_type} :except => [:#{action}]"

          expect { expect(controller).not_to match.except(action) }.to fail_with_message(message)
        end
      end
    end


    private

    def add_callback(kind, callback_type, callback, options = {})
      controller.class.__send__("#{kind}_#{callback_type}", callback, options)
    end
  end

  describe '#use_before_filter' do
    it_behaves_like 'CallbackMatcher', :before, :filter
  end

  describe '#use_after_filter' do
    it_behaves_like 'CallbackMatcher', :after, :filter
  end

  describe '#use_around_filter' do
    it_behaves_like 'CallbackMatcher', :around, :filter
  end

  if rails_4_x?
    describe '#use_before_action' do
      it_behaves_like 'CallbackMatcher', :before, :action
    end

    describe '#use_after_action' do
      it_behaves_like 'CallbackMatcher', :after, :action
    end

    describe '#use_around_action' do
      it_behaves_like 'CallbackMatcher', :around, :action
    end
  end
end
