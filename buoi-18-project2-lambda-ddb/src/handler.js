// Lambda handler cho Project 2 — buổi 18.
// Runtime: nodejs22.x. Sử dụng AWS SDK v3.
// Hỗ trợ event API Gateway proxy (REST API):
//   - GET  /items        → trả về toàn bộ item (Scan).
//   - POST /items        → tạo / update item (PutItem). Body JSON: { "id": "...", ... }
// Lưu ý: Scan dùng được cho mức học, production phải dùng Query/Index.

"use strict";

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  ScanCommand,
  PutCommand,
} = require("@aws-sdk/lib-dynamodb");

// Khởi tạo client 1 lần ở scope module để tái sử dụng giữa các invocation (warm start).
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const TABLE_NAME = process.env.TABLE_NAME;

// Helper trả về response chuẩn API Gateway proxy.
function response(statusCode, body) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}

exports.handler = async (event) => {
  console.log("Event:", JSON.stringify(event));

  if (!TABLE_NAME) {
    return response(500, { error: "TABLE_NAME env var chưa được set" });
  }

  const method = (event.httpMethod || "").toUpperCase();

  try {
    if (method === "GET") {
      // Lấy danh sách item — Scan toàn bộ table (chỉ dùng cho mức học).
      const out = await ddb.send(new ScanCommand({ TableName: TABLE_NAME }));
      return response(200, { items: out.Items || [], count: out.Count || 0 });
    }

    if (method === "POST") {
      // Tạo / cập nhật item.
      let payload;
      try {
        payload = event.body ? JSON.parse(event.body) : {};
      } catch (e) {
        return response(400, { error: "Body không phải JSON hợp lệ" });
      }

      if (!payload.id || typeof payload.id !== "string") {
        return response(400, {
          error: "Trường 'id' (string) là bắt buộc trong body",
        });
      }

      await ddb.send(
        new PutCommand({
          TableName: TABLE_NAME,
          Item: payload,
        }),
      );

      return response(201, { message: "Item đã được lưu", item: payload });
    }

    return response(405, { error: `Method ${method} không hỗ trợ` });
  } catch (err) {
    console.error("Lỗi xử lý:", err);
    return response(500, {
      error: "Internal server error",
      detail: err.message,
    });
  }
};
