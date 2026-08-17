# frozen_string_literal: true

require "etc"

module I18n::Tasks::Concurrent
  module ProcessMap
    class WorkerError < StandardError; end

    module_function

    def map(items, processes: Etc.nprocessors, &block)
      items = items.to_a
      return items.map(&block) unless supported? && items.size > 1 && processes > 1

      worker_count = [items.size, processes].min
      batches = items.each_with_index.group_by { |_item, index| index % worker_count }.values
      workers = batches.map { |batch| start_worker(batch, block) }
      payloads = workers.map { |_pid, reader| Marshal.load(reader) }
      workers.each { |pid, _reader| Process.wait(pid) }

      payloads.each do |status, *details|
        next if status == :ok

        class_name, message, backtrace = details
        error = WorkerError.new("#{class_name}: #{message}")
        error.set_backtrace(backtrace)
        raise error
      end

      payloads.flat_map { |_status, results| results }.sort_by(&:first).map(&:last)
    ensure
      workers&.each do |pid, reader|
        reader.close unless reader.closed?
        Process.wait(pid) if Process.waitpid(pid, Process::WNOHANG).nil?
      rescue Errno::ECHILD
        nil
      end
    end

    def supported?
      RUBY_ENGINE == "ruby" && !Gem.win_platform? && Process.respond_to?(:fork)
    end

    def start_worker(batch, block)
      reader, writer = IO.pipe
      pid = Process.fork do
        reader.close
        payload = begin
          [:ok, batch.map { |item, index| [index, block.call(item)] }]
        rescue Exception => e # rubocop:disable Lint/RescueException
          [:error, e.class.name, e.message, e.backtrace]
        end
        Marshal.dump(payload, writer)
        writer.close
        exit! 0
      end
      writer.close
      [pid, reader]
    end
    private_class_method :start_worker
  end
end
