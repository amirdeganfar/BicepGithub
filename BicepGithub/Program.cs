using Azure.Messaging.ServiceBus;

var builder = WebApplication.CreateBuilder(args);

var sbConn = builder.Configuration["ServiceBus:ConnectionString"] 
             ?? builder.Configuration["ServiceBus__ConnectionString"];
var queueName = builder.Configuration["ServiceBus:QueueName"] 
                ?? builder.Configuration["ServiceBus__QueueName"];

builder.Services.AddSingleton(_ => new ServiceBusClient(sbConn!));
builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<ServiceBusClient>().CreateSender(queueName));
builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<ServiceBusClient>().CreateReceiver(queueName));

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.MapPost("/messages", async (ServiceBusSender sender, Message m) =>
{
    await sender.SendMessageAsync(new ServiceBusMessage(m.Body));
    return Results.Accepted();
});

app.MapGet("/messages", async (ServiceBusReceiver receiver) =>
{
    var msg = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(2));
    if (msg is null) return Results.NoContent();
    var body = msg.Body.ToString();
    await receiver.CompleteMessageAsync(msg);
    return Results.Ok(new { body });
}).WithOpenApi();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.Run();

record Message(string Body);