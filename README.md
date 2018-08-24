# tableau-client

## Usage

```
$ bundle exec console
> server = TableauServerClient::Server.new('<server_url>', '<username>', '<password>')
> site = server.sites.select {|s| s.name == 'Default'}.first
> site.workbooks.first.path
=> "sites/1c83a360-6f5f-4517-a329-c5f42ea21233/workbooks/02cb3598-616a-4d58-b1df-cf6d6dd90b7e"
> site.workbooks.first.name
=> "My Workbook"
```
