defmodule Jot.Timestamp do

  def now do
    :os.system_time(:seconds)
  end

  def to_ecto_datetime(timestamp) do
    timestamp
    |> to_erl_datetime
    |> Ecto.DateTime.from_erl()
  end

  def to_erl_datetime(timestamp) do
    timestamp
    |> +(epoch_timestamp)
    |> :calendar.gregorian_seconds_to_datetime
  end

  def from_erl_datetime(datetime) do
    datetime
    |> :calendar.datetime_to_gregorian_seconds
    |> -(epoch_timestamp)
  end

  defp epoch_timestamp do
    epoch_datetime = {{1970, 1, 1}, {0, 0, 0}}
    :calendar.datetime_to_gregorian_seconds(epoch_datetime)
  end
end
