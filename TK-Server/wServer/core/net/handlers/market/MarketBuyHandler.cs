﻿using common;
using common.database;
using Nancy.Json;
using System;
using System.IO;
using System.Net;
using wServer.networking;
using wServer.networking.packets;
using wServer.networking.packets.outgoing.market;

namespace wServer.core.net.handlers.market
{
    public class MarketBuyHandler : IMessageHandler
    {
        public override MessageId MessageId => MessageId.MARKET_BUY;

        private const int TAX_PERCENTAGE = 5;

        public override void Handle(Client client, NReader rdr, ref TickTime time)
        {
            var id = rdr.ReadInt32();

            if (!IsAvailable(client) || !IsEnabledOrIsVipMarket(client))
                return;

            var db = client.Player.GameServer.Database;
            var marketData = DbMarketData.GetSpecificOffer(client?.Account?.Database, id);

            if (marketData == null)
            {
                client.SendPacket(new MarketBuyResult()
                {
                    Code = MarketBuyResult.ERROR,
                    Description = "Something wrong happened, try again. (Item doesn't exist in Market)"
                });
                client.Player?.SendError("That item doesn't exist.");
                return;
            }

            var sellerId = db.ResolveId(marketData.SellerName);
            var sellerAcc = db.GetAccount(sellerId);
            if(sellerAcc == null)
            {
                client.Player?.SendError("Unable to find seller.");
                return;
            }

            var item = client.Player.GameServer.Resources.GameData.Items[marketData.ItemType];

            var buyerId = db.ResolveId(client.Player.Name);
            var buyerAcc = db.GetAccount(client.Player.AccountId);

            if (buyerId == 0 || buyerAcc == null)
            {
                client.SendPacket(new MarketBuyResult()
                {
                    Code = MarketBuyResult.ERROR,
                    Description = "Something wrong happened, try again. (Unexpected Error)"
                });
                client.Player?.SendError("Something wrong happened, try again. (Unexpected Error)");
                return;
            }
            if (sellerId == 0 || sellerAcc == null)
            {
                client.SendPacket(new MarketBuyResult()
                {
                    Code = MarketBuyResult.ERROR,
                    Description = "Something wrong happened, try again. (Seller Account not exist)"
                });
                client.Player?.SendError("Something wrong happened, try again. (Seller Account not exist)");
                return;
            }
            if (item == null)
            {
                client.SendPacket(new MarketBuyResult()
                {
                    Code = MarketBuyResult.ERROR,
                    Description = "Something wrong happened, try again. (Item not registered in Server)"
                });
                client.Player?.SendError("Something wrong happened, try again. (Item not registered in Server)");
                return;
            }
            if (buyerAcc.Fame < marketData.Price)
            {
                client.SendPacket(new MarketBuyResult()
                {
                    Code = MarketBuyResult.ERROR,
                    Description = "Your fame is not enough to buy this item!"
                });
                client.Player?.SendError("Not enough Fame.");
                return;
            }

            /* Add fame to the Seller */
            AddFameToSeller(client, sellerAcc, marketData.Price, item.ObjectId);

            /* Remove fame to Buyer */
            RemoveFameToBuyer(buyerAcc, marketData.Price, client);

            db.RemoveMarketEntrySafety(sellerAcc, marketData.Id);

            if (!string.IsNullOrEmpty(marketData.ItemData))
                DbSpecialVault.AddItem(buyerAcc, marketData.ItemType, marketData.ItemData);
            else
                db.AddGift(buyerAcc, marketData.ItemType);

            client.SendPacket(new MarketBuyResult()
            {
                Code = -1,
                Description = $"You have successfully bought: {item.ObjectId}",
                OfferId = marketData.Id
            });

            //Send the item to the API
            SendToAPIAsync(marketData.ItemType, marketData.Price);
        }

        private void SendToAPIAsync(int itemId, int price)
        {
            System.Threading.Tasks.Task.Factory.StartNew(() =>
            {
                var httpWebRequest = (HttpWebRequest)WebRequest.Create($"https://tkprices.herokuapp.com/api/item/addtx");
                httpWebRequest.ContentType = "application/json";
                httpWebRequest.Method = "POST";

                using (var streamWriter = new StreamWriter(httpWebRequest.GetRequestStream()))
                {
                    string json = new JavaScriptSerializer().Serialize(new APIItem() //Added new Package, Nancy.Json, if you don't have it, search it in NuGet
                    {
                        itemID = itemId,
                        value = price
                    });
                    streamWriter.Write(json);
                    streamWriter.Flush();
                    streamWriter.Close();
                }

                try
                {
                    var httpResponse = (HttpWebResponse)httpWebRequest.GetResponse();
                    using (var streamReader = new StreamReader(httpResponse.GetResponseStream()))
                    {
                        var result = streamReader.ReadToEnd();
                        if (!result.Contains("200")) //200 is normal result, if it doesn't contains it, somethingb bad happened
                            Console.WriteLine(result);
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine(e);
                    return;
                }
            });
        }

        private void AddFameToSeller(Client client, DbAccount acc, int realPrice, string itemId)
        {
            var tax = GetTax(realPrice);
            var resultPrice = realPrice - tax;

            acc.Reload("fame");
            acc.Reload("totalFame");
            acc.Fame += resultPrice;
            acc.TotalFame += resultPrice;
            acc.FlushAsync();
            acc.Reload("fame");
            acc.Reload("totalFame");

            client.Player.GameServer.ChatManager.SendInfoMarket(acc.AccountId, itemId, realPrice, resultPrice, TAX_PERCENTAGE);
        }

        private void RemoveFameToBuyer(DbAccount acc, int realPrice, Client client = null)
        {
            acc.Reload("fame");
            acc.Reload("totalFame");
            acc.Fame -= realPrice;
            acc.TotalFame -= realPrice;
            acc.FlushAsync();
            acc.Reload("fame");
            acc.Reload("totalFame");

            if (client != null && client.Player != null)
            {
                client.Player.CurrentFame = acc.Fame;
                client.Player.SendInfo("<Marketplace> The purchase item has been sent to your gift chests at Vault.");
            }
        }

        internal class APIItem //if u want, you can remove this and make it different?
        {
            public string secret = "BNvYPJD35c94ng5c";
            public int itemID;
            public int value;
        }

        private int GetTax(int price) => TAX_PERCENTAGE * price / 100;
    }
}
