package ru.bssg.damask.apirx_test.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;
import ru.bssg.damask.apirx_test.service.YandexDbService;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("v1")
public class MainController {

    private final YandexDbService tokenService;

    @RequestMapping(value = "/tokenize_ydb_many_test", method = RequestMethod.POST, produces = { "application/json"})
    public Mono<ResponseEntity<List<String>>> tokenizeYdbManeOne(@RequestBody List<String> reqData) {
        return tokenService.tokenizeManyTest(reqData).map(ResponseEntity::ok);
    }

}
